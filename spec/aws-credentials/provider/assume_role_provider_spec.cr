require "../../spec_helper"
require "awscr-signer"

module Aws::Credentials
  describe AssumeRoleProvider do
    it "resolve credentials from sts endpoint" do
      server, relative_uri = Scenarios.scenario_sts
      begin
        url = "http://127.0.0.1:#{server[:port]}#{relative_uri}"
        signer = ->(request : HTTP::Request, credentials : Credentials) {
          Awscr::Signer::Signers::V4.new("sts", "ap-northeast-1", credentials.access_key_id, credentials.secret_access_key).sign(request)
          request
        }
        provider = AssumeRoleProvider.new(
          role_arn: "arn:aws:iam::123456789012:role/demo",
          role_session_name: "Bob",
          sts_client: STSClient.new(
            contractor_credential_provider: Providers.new([SimpleCredentials.new(
              access_key_id: "KEY_ID",
              secret_access_key: "SECRET_KEY",
            )] of Provider).as(Provider),
            signer: signer,
            endpoint: url,
          ),
        )
        actual = provider.credentials
        actual.access_key_id.should eq "ASIAIOSFODNN7EXAMPLE"
        actual.secret_access_key.should eq "wJalrXUtnFEMI/K7MDENG/bPxRfiCYzEXAMPLEKEY"
        actual.session_token.should eq "AQoDYXdzEPT//////////wEXAMPLEtc764bNrC9SAPBSM22wDOk4x4HIZ8j4FZTwdQWLWsKWHGBuFqwAeMicRXmxfpSPfIeoIYRqTflfKD8YUuwthAx7mSEI/qkPpKPi/kMcGdQrmGdeehM4IC1NtBmUpp2wUE8phUZampKsburEDy0KPkyQDYwT7WZ0wq5VSXDvp75YU9HFvlRd8Tx6q6fE8YQcHNVXAkiY9q6d+xo0rKwT38xVqr7ZD0u0iPPkUL64lIZbqBAz+scqKmlzm8FDrypNC9Yjc8fPOLn9FX9KSYvKTr4rvx3iSIlTJabIQwj2ICCR/oLxBA=="
        actual.expiration.should_not be_nil
        actual.expiration.try do |exp|
          exp.should be > Time.utc
        end
      ensure
        server[:server].close
      end
    end

    it "resolve no credentials" do
      server, relative_uri = Scenarios.scenario_sts
      begin
        url = "http://127.0.0.1:#{server[:port]}#{relative_uri}notavairable"
        signer = ->(request : HTTP::Request, credentials : Credentials) {
          Awscr::Signer::Signers::V4.new("sts", "ap-northeast-1", credentials.access_key_id, credentials.secret_access_key).sign(request)
          request
        }
        provider = AssumeRoleProvider.new(
          role_arn: "arn:aws:iam::123456789012:role/demo",
          role_session_name: "Bob",
          sts_client: STSClient.new(
            contractor_credential_provider: Providers.new([EnvProvider.new, SharedCredentialFileProvider.new] of Provider).as(Provider),
            signer: signer,
            endpoint: url,
          ),
        )
        # Expects non OK(200) response status.
        expect_raises(MissingCredentials) do
          provider.credentials
        end
      ensure
        server[:server].close
      end
    end

    it "resolve no credentials because of invalid response entity" do
      server, relative_uri = Scenarios.scenario_sts_invalid
      begin
        url = "http://127.0.0.1:#{server[:port]}#{relative_uri}"
        signer = ->(request : HTTP::Request, credentials : Credentials) {
          Awscr::Signer::Signers::V4.new("sts", "ap-northeast-1", credentials.access_key_id, credentials.secret_access_key).sign(request)
          request
        }
        provider = AssumeRoleProvider.new(
          role_arn: "arn:aws:iam::123456789012:role/demo",
          role_session_name: "Bob",
          sts_client: STSClient.new(
            contractor_credential_provider: Providers.new([EnvProvider.new, SharedCredentialFileProvider.new] of Provider).as(Provider),
            signer: signer,
            endpoint: url,
          ),
        )
        # Expects non OK(200) response status.
        expect_raises(MissingCredentials) do
          provider.credentials
        end
      ensure
        server[:server].close
      end
    end

    it "can refresh credentials" do
      server, relative_uri = Scenarios.scenario_sts(1.second)
      begin
        url = "http://127.0.0.1:#{server[:port]}#{relative_uri}"
        signer = ->(request : HTTP::Request, credentials : Credentials) {
          Awscr::Signer::Signers::V4.new("sts", "ap-northeast-1", credentials.access_key_id, credentials.secret_access_key).sign(request)
          request
        }
        provider = AssumeRoleProvider.new(
          role_arn: "arn:aws:iam::123456789012:role/demo",
          role_session_name: "Bob",
          sts_client: STSClient.new(
            contractor_credential_provider: Providers.new([SimpleCredentials.new(
              access_key_id: "KEY_ID",
              secret_access_key: "SECRET_KEY",
            )] of Provider).as(Provider),
            signer: signer,
            endpoint: url,
          ),
        )
        initial = provider.credentials
        initial.access_key_id.should eq "ASIAIOSFODNN7EXAMPLE"
        initial.secret_access_key.should eq "wJalrXUtnFEMI/K7MDENG/bPxRfiCYzEXAMPLEKEY"
        initial.session_token.should eq "AQoDYXdzEPT//////////wEXAMPLEtc764bNrC9SAPBSM22wDOk4x4HIZ8j4FZTwdQWLWsKWHGBuFqwAeMicRXmxfpSPfIeoIYRqTflfKD8YUuwthAx7mSEI/qkPpKPi/kMcGdQrmGdeehM4IC1NtBmUpp2wUE8phUZampKsburEDy0KPkyQDYwT7WZ0wq5VSXDvp75YU9HFvlRd8Tx6q6fE8YQcHNVXAkiY9q6d+xo0rKwT38xVqr7ZD0u0iPPkUL64lIZbqBAz+scqKmlzm8FDrypNC9Yjc8fPOLn9FX9KSYvKTr4rvx3iSIlTJabIQwj2ICCR/oLxBA=="
        initial.expiration.should_not be_nil
        initial.expiration.try do |exp|
          exp.should be > Time.utc
        end

        sleep 1.2.seconds

        provider.refresh
        refreshed = provider.credentials
        refreshed.expiration.should_not be_nil
        refreshed.expiration.try do |refreshed_expiration|
          initial.expiration.try do |initial_expiration|
            refreshed_expiration.should be > initial_expiration
          end
        end
      ensure
        server[:server].close
      end
    end
  end
end
