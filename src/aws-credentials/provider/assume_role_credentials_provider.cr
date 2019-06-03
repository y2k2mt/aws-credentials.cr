require "../sts_client"

module Aws::Credentials
  class AssumeRoleCredentialProvider
    include Provider

    def initialize(
      @role_arn : String,
      @role_session_name : String,
      @sts_client : STSClient,
      @duration : Time::Span? = nil,
      @policy : JSON::Any? = nil
    )
    end

    def credentials : Credentials
      @sts_client.assume_role(@role_arn, @role_session_name, @duration, @policy)
    end
  end
end
