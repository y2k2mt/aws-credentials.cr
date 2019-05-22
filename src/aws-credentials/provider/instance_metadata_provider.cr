require "http/client"
require "json"

module Aws::Credentials
  class InstanceMetadataProvider
    include Provider
    include CredentialsWithExpiration

    @resolved : Credentials? = nil

    def initialize(
      @iam_security_credential_url : String = "http://169.254.169.254/latest/meta-data/iam/security-credentials/",
      @current_time_provider : Proc(Time) = ->{ Time.now }
    )
    end

    def credentials : Credentials
      if unresolved_or_expired @resolved, @current_time_provider
        @resolved = resolve
      end
      @resolved.not_nil!
    end

    private def resolve
      url = URI.parse @iam_security_credential_url
      http = HTTP::Client.new url
      http.connect_timeout = 5.seconds
      response = http.get url.path.not_nil!
      case response.status_code
      when 200
        resolved_role_name = response.body.lines.first
        response = http.get "#{@iam_security_credential_url}#{resolved_role_name}"
        case response.status_code
        when 200
          begin
            credentials = JSON.parse(response.body).as_h
            Credentials.new(
              access_key_id: credentials["AccessKeyId"].as_s,
              secret_access_key: credentials["SecretAccessKey"].as_s,
              session_token: credentials["Token"]?.try &.as_s?,
              expiration: credentials["Expiration"]?.try &.as_s?.try do |ex|
                Time.parse_iso8601(ex)
              end
            )
          rescue e
            raise MissingCredentials.new("Failed to parse instance metadata : #{e.message}")
          end
        else
          raise MissingCredentials.new("Failed to resolve security credentials from IAM role : #{response.status_code}:#{response.body}")
        end
      else
        raise MissingCredentials.new("Failed to resolve IAM role name : #{response.status_code}:#{response.body}")
      end
    end
  end
end
