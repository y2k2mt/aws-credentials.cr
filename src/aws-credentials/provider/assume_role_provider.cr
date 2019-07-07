require "../sts_client"

module Aws::Credentials
  # Resolving credential via AWS Security Token Service(STS) as assume role.
  #
  # https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html
  class AssumeRoleProvider
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
      @sts_client.assume_role @role_arn, @role_session_name, @duration, @policy
    end
  end
end
