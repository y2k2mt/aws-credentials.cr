require "json"
require "./http_client"
require "./xml"

module Aws::Credentials
  class STSClient
    def initialize(
      @contractor_credential_provider : Provider,
      @signer : Proc(HTTP::Request, Credentials, HTTP::Request),
      region : String? = nil,
      @endpoint : String = region ? "https://sts.#{region}.amazonaws.com" : "https://sts.amazonaws.com"
    )
    end

    def assume_role(
      @role_arn : String,
      @role_session_name : String,
      @duration : Time::Span? = nil,
      @policy : JSON::Any? = nil
    ) : Credentials
      param = HTTP::Params.build { |form|
        form.add "Version", "2011-06-15"
        form.add "Action", "AssumeRole"
        form.add "RoleSessionName", @role_session_name
        form.add "RoleArn", @role_arn
        @policy.try { |p|
          form.add "Policy", p.to_json
        }
        @duration.try { |d|
          form.add "DurationSeconds", d.total_seconds.to_i64.to_s
        }
        form
      }
      endpoint_uri = URI.parse @endpoint
      request = HTTP::Request.new "GET", endpoint_uri.path || "/"
      request.headers["Host"] = endpoint_uri.host.not_nil!
      request.query = param
      signed_request = @signer.call(request, @contractor_credential_provider.credentials)
      response = HTTPClient.exec endpoint_uri, signed_request
      case response.status_code
      when 200
        xml = XML.new response.body
        credentials_xml_root = "//AssumeRoleResponse/AssumeRoleResult/Credentials"
        Credentials.new(
          access_key_id: xml.string("#{credentials_xml_root}/AccessKeyId"),
          secret_access_key: xml.string("#{credentials_xml_root}/SecretAccessKey").gsub(" ", "").gsub("\n", ""),
          session_token: xml.string("#{credentials_xml_root}/SessionToken").gsub(" ", "").gsub("\n", ""),
          expiration: Time.parse_iso8601(xml.string("#{credentials_xml_root}/Expiration")),
        )
      else
        raise "Failed to assume role via sts : #{response.status_code} : #{response.body}"
      end
    rescue e
      raise MissingCredentials.new e
    end
  end
end
