require "json"
require "../http_client"

module Aws::Credentials
  # Resolving credential from instance metadata.
  #
  # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html
  class InstanceMetadataProvider
    include Provider

    def initialize(
      @iam_security_credential_url : String = "http://169.254.169.254/latest/meta-data/iam/security-credentials/"
    )
    end

    def credentials : Credentials
      response = HTTPClient.get URI.parse(@iam_security_credential_url)
      case response.status_code
      when 200
        resolved_role_name = response.body.lines.first
        response = HTTPClient.get URI.parse("#{@iam_security_credential_url}#{resolved_role_name}")
        case response.status_code
        when 200
          credentials = JSON.parse(response.body).as_h
          Credentials.new(
            access_key_id: credentials["AccessKeyId"].as_s,
            secret_access_key: credentials["SecretAccessKey"].as_s,
            session_token: credentials["Token"]?.try &.as_s?,
            expiration: credentials["Expiration"]?.try &.as_s?.try do |exp|
              Time.parse_iso8601 exp
            end
          )
        else
          raise MissingCredentials.new "Failed to resolve security credentials from IAM role : #{response.status_code}:#{response.body}"
        end
      else
        raise MissingCredentials.new "Failed to resolve IAM role name : #{response.status_code}:#{response.body}"
      end
    rescue e
      raise MissingCredentials.new e
    end
  end
end
