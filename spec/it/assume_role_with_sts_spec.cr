require "../spec_helper"
require "awscr-signer"

module Aws::Credentials
  describe AssumeRoleProvider do
    it "resolved with STS" do
      region = ENV["AC1_AWS_REGION"]?
      role_arn = ENV["AC1_ROLE_ARN"]?
      access_key_id = ENV["AC1_AWS_ACCESS_KEY_ID"]?
      secret_access_key = ENV["AC1_AWS_SECRET_ACCESS_KEY"]?

      unless region && role_arn && access_key_id && secret_access_key
        next
      end

      signer = ->(request : HTTP::Request, credentials : Credentials) {
        Awscr::Signer::Signers::V4.new("sts", region, credentials.access_key_id, credentials.secret_access_key).sign(request)
        request
      }

      role_provider = AssumeRoleProvider.new(
        role_arn: role_arn,
        role_session_name: "Bob",
        sts_client: STSClient.new(
          contractor_credential_provider: Providers.new([SimpleCredentials.new(
            access_key_id: access_key_id,
            secret_access_key: secret_access_key,
          )] of Provider).as(Provider),
          signer: signer,
          region: region,
        ),
        duration: 900.seconds,
      )

      role_provider.credentials
      provider = Providers.new [
        role_provider,
      ] of Provider

      actual = provider.credentials
      actual.access_key_id.should_not be_nil
      actual.secret_access_key.should_not be_nil
      actual.session_token.should_not be_nil
    end
  end

  describe AssumeRoleWithWebIdentityProvider do
    it "resolved with STS" do
      region = ENV["AWS_AWS_REGION"]?
      role_arn = ENV["AWS_ROLE_ARN"]?
      web_identity_token_file = ENV["AWS_WEB_IDENTITY_TOKEN_FILE"]?

      unless region && role_arn && web_identity_token_file
        next
      end

      # With this call, all values should be picked from the environment variables
      # and the default duration should be used
      role_provider = AssumeRoleWithWebIdentityProvider.new(
        role_session_name: "Bob"
      )

      role_provider.credentials
      provider = Providers.new [
        role_provider,
      ] of Provider

      actual = provider.credentials
      actual.access_key_id.should_not be_nil
      actual.secret_access_key.should_not be_nil
      actual.session_token.should_not be_nil
    end
  end
end
