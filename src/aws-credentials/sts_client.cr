require "./http_client"
require "./xml"

module Aws::Credentials
  class STSClient
    def initialize(
      @contractor_credential_provider : Provider,
      @signer : Proc(HTTP::Request, Credentials, HTTP::Request),
      @endpoint : String = "https://sts.amazonaws.com"
    )
    end

    def assume_role(
      @role_arn : String,
      @role_session_name : String,
      @duration_seconds : Time::Span?,
      @policy : JSON::Any?
    ) : Credentials
      param = HTTP::Params.build { |form|
        form.add "Action", "AssumeRole"
        form.add "RoleSessionName", @role_session_name
        form.add "RoleArn", @role_arn
        @policy.try { |p|
          form.add "Policy", p.to_json
        }
        @duration_seconds.try { |d|
          form.add "DurationSeconds", d.total_seconds.to_i64.to_s
        }
        form
      }
      endpoint_uri = URI.parse @endpoint
      request = HTTP::Request.new("GET", endpoint_uri.path || "/")
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
        raise MissingCredentials.new "Failed to assume role via sts : #{response.status_code} : #{response.body}"
      end
    rescue e
      raise MissingCredentials.new e
    end
  end
end
