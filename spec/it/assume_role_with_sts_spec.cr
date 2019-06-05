require "../spec_helper"
require "awscr-signer"

module Aws::Credentials
  describe AssumeRoleProvider do
    it "resolved" do
      region = ENV["AC1_AWS_REGION"]?
      role_arn = ENV["AC1_ROLE_ARN"]?
      access_key_id = ENV["AC1_AWS_ACCESS_KEY_ID"]?
      secret_access_key = ENV["AC1_AWS_SECRET_ACCESS_KEY"]?

      if !(region && role_arn && access_key_id && secret_access_key)
        next
      end

      signer = ->(request : HTTP::Request, credentials : Credentials) {
        Awscr::Signer::Signers::V4.new("sts", region.not_nil!, credentials.access_key_id, credentials.secret_access_key).sign(request)
        request
      }

      role_provider = AssumeRoleProvider.new(
        role_arn: role_arn.not_nil!,
        role_session_name: "Bob",
        sts_client: STSClient.new(
          contractor_credential_provider: Providers.new([SimpleCredentials.new(
            access_key_id: access_key_id.not_nil!,
            secret_access_key: secret_access_key.not_nil!,
          )] of Provider).as(Provider),
          signer: signer,
          region: region.not_nil!,
        ),
        duration: 900.seconds,
      )

      role_provider.credentials
      provider = Providers.new [
        role_provider,
      ] of Provider

      pp! actual = provider.credentials
      actual.access_key_id.should_not be_nil
      actual.secret_access_key.should_not be_nil
      actual.session_token.should_not be_nil
    end
  end
end
