require "../sts_client"

module Aws::Credentials
  # Resolving credential via AWS Security Token Service(STS) as assume role.
  #
  # https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRoleWithWebIdentity.html
  class AssumeRoleWithWebIdentityProvider
    include Provider

    def initialize(
      @role_arn : String,
      @role_session_name : String,
      @web_identity_token : String,
      @sts_client : STSClient,
      @duration : Time::Span? = nil,
      @policy : JSON::Any? = nil
    )
    end

    # An option for a container where almost all the values are defined in
    # an environment variables
    def initialize(@role_session_name : String, @duration : Time::Span? = nil, @policy : JSON::Any? = nil)
      @role_arn = ENV["AWS_ROLE_ARN"]
      @web_identity_token = File.read(ENV["AWS_WEB_IDENTITY_TOKEN_FILE"])
      # No need to sign the request, so the default client is fine
      @sts_client = STSClient.new(region: ENV["AWS_REGION"])
    end

    def credentials : Credentials
      @sts_client.assume_role_with_web_identity(
        @role_arn,
        @role_session_name,
        @web_identity_token,
        @duration,
        @policy
      )
    end
  end
end
