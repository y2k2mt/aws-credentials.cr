require "../sts_client"

module Aws::Credentials
  # Resolving credential via AWS Security Token Service(STS) as assume role.
  #
  # https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRoleWithWebIdentity.html
  class AssumeRoleWithWebIdentityProvider
    include Provider

    def initialize(
      @role_session_name : String,
      @role_arn : String? = nil,
      @web_identity_token : String? = nil,
      sts_client : STSClient? = nil,
      @duration : Time::Span? = nil,
      @policy : JSON::Any? = nil
    )
      # No need to sign the request, so the default client is fine
      @sts_client = sts_client || STSClient.new(region: ENV["AWS_REGION"]? || "us-east-1")
    end

    def credentials : Credentials
      role_arn = @role_arn || ENV["AWS_ROLE_ARN"]
      web_identity_token = @web_identity_token || File.read(ENV["AWS_WEB_IDENTITY_TOKEN_FILE"])
      @sts_client.assume_role_with_web_identity(
        role_arn,
        @role_session_name,
        web_identity_token,
        @duration,
        @policy
      )
    end
  end
end
