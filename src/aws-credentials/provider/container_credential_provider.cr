require "json"
require "../http_client"

module Aws::Credentials
  # Resolving credential from task role in container.
  #
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html
  class ContainerCredentialProvider
    include Provider

    def initialize(
      @container_credential_url : String? = nil
    )
    end

    private def lazy_resolve_url
      @container_credential_url = "http://169.254.170.2#{ENV.fetch("AWS_CONTAINER_CREDENTIALS_RELATIVE_URI")}" unless @container_credential_url
      @container_credential_url.not_nil!
    end

    def credentials : Credentials
      response = HTTPClient.get URI.parse(lazy_resolve_url)
      case response.status_code
      when 200
        begin
          credentials = JSON.parse(response.body).as_h
          Credentials.new(
            access_key_id: credentials["AccessKeyId"].as_s,
            secret_access_key: credentials["SecretAccessKey"].as_s,
            session_token: credentials["Token"]?.try &.as_s?,
            expiration: credentials["Expiration"]?.try &.as_s?.try do |ex|
              Time.parse_iso8601 ex
            end
          )
        end
      else
        raise MissingCredentials.new "Failed to resolve credentials from container IAM role : #{response.status_code}:#{response.body}"
      end
    rescue e
      raise MissingCredentials.new e
    end
  end
end
