require "../sts_client"

module Aws::Credentials
  # Resolving credential via AWS Security Token Service(STS) as assume role.
  #
  # https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html
  class AssumeRoleProvider
    include Provider

    @last_credentials : Credentials? = nil

    def initialize(
      @role_arn : String,
      @role_session_name : String,
      @sts_client : STSClient,
      @duration : Time::Span? = nil,
      @policy : JSON::Any? = nil,
      logger : Log = ::Log.for("AWS.Credentials"),
    )
      @logger = logger.for("AssumeRoleProvider")
    end

    def credentials : Credentials
      refresh unless @last_credentials
      @last_credentials || raise MissingCredentials.new("Unable to retrieve credentials")
    end

    def refresh : Nil
      @last_credentials = @sts_client.assume_role(@role_arn, @role_session_name, @duration, @policy)
    end
  end
end
