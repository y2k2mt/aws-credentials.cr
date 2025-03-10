require "../../spec_helper"
require "awscr-signer"

module Aws::Credentials
  describe AssumeRoleWithWebIdentityProvider do
    it "resolve credentials from sts endpoint" do
      server, relative_uri = Scenarios.scenario_sts
      begin
        url = "http://127.0.0.1:#{server[:port]}#{relative_uri}"
        token = <<-JWT
        eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
        JWT
        provider = AssumeRoleWithWebIdentityProvider.new(
          role_arn: "arn:aws:iam::123456789012:role/demo",
          role_session_name: "Bob",
          web_identity_token: token,
          sts_client: STSClient.new(
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
        token = <<-JWT
        eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
        JWT
        provider = AssumeRoleWithWebIdentityProvider.new(
          role_arn: "arn:aws:iam::123456789012:role/demo",
          role_session_name: "Bob",
          web_identity_token: token,
          sts_client: STSClient.new(
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
        token = <<-JWT
        eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
        JWT
        provider = AssumeRoleWithWebIdentityProvider.new(
          role_arn: "arn:aws:iam::123456789012:role/demo",
          role_session_name: "Bob",
          web_identity_token: token,
          sts_client: STSClient.new(
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
        token = <<-JWT
        eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
        JWT
        provider = AssumeRoleWithWebIdentityProvider.new(
          role_arn: "arn:aws:iam::123456789012:role/demo",
          role_session_name: "Bob",
          web_identity_token: token,
          sts_client: STSClient.new(
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
