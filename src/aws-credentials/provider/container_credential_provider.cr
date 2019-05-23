require "../http_client"

module Aws::Credentials
  class ContainerCredentialProvider
    include Provider
    include CredentialsWithExpiration

    @resolved : Credentials? = nil

    def initialize(
      @container_credential_url : String? = nil,
      @current_time_provider : Proc(Time) = ->{ Time.now }
    )
    end

    def credentials : Credentials
      pp "aws-credentials: Resolving #{@resolved} : #{@current_time_provider}"
      if unresolved_or_expired @resolved, @current_time_provider
        pp "aws-credentials: Expired! Updating Credentials."
        @resolved = resolve_credentials
      end
      @resolved.not_nil!
    end

    private def lazy_resolve_url
      if !@container_credential_url
        "http://169.254.170.2#{ENV.fetch("AWS_CONTAINER_CREDENTIALS_RELATIVE_URI")}"
      else
        @container_credential_url.not_nil!
      end
    end

    private def resolve_credentials : Credentials
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
              Time.parse_iso8601(ex)
            end
          )
        rescue e
          raise MissingCredentials.new("Failed to parse container credentials : #{e.message}")
        end
      else
        raise MissingCredentials.new("Failed to resolve credentials from container IAM role : #{response.status_code}:#{response.body}")
      end
    end
  end
end
