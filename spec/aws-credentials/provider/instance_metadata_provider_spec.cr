require "../../spec_helper"

module Aws::Credentials
  describe InstanceMetadataProvider do
    describe "credentials" do
      it "resolve credentialss from container credentials endpoint" do
        server, relative_uri, expiration = Scenarios.scenario_two
        begin
          current = "2019-05-20T11:00:00Z"
          provider = InstanceMetadataProvider.new(
            iam_security_credential_url: "http://127.0.0.1:#{server[:port]}#{relative_uri}",
            current_time_provider: ->{ Time.parse_iso8601 current }
          )
          actual = provider.credentials
          actual.access_key_id.should eq "AKIAIEZLS3DOSUZ7RS01"
          actual.secret_access_key.should eq "pC3z33ypXyiN3309kUykBriMkaKiADSodYZXJTKkCNc"
          actual.expiration.should eq Time.parse_iso8601 expiration
          reprovided = provider.credentials
          # Expects same
          actual.session_token.should eq reprovided.session_token
        ensure
          server[:server].close
        end
      end
    end
    describe "credentials" do
      it "container credentials endpoint replies not found" do
        server, _, _ = Scenarios.scenario_two
        begin
          provider = InstanceMetadataProvider.new(iam_security_credential_url: "http://127.0.0.1:#{server[:port]}/not_avairable")
          expect_raises(MissingCredentials) do
            provider.credentials
          end
        ensure
          server[:server].close
        end
      end
    end
    describe "credentials" do
      it "container credentials expired" do
        server, relative_uri, expiration = Scenarios.scenario_two
        begin
          current = "2019-05-20T13:00:00Z"
          provider = InstanceMetadataProvider.new(
            iam_security_credential_url: "http://127.0.0.1:#{server[:port]}#{relative_uri}",
            current_time_provider: ->{ Time.parse_iso8601 current }
          )
          actual = provider.credentials
          actual.access_key_id.should eq "AKIAIEZLS3DOSUZ7RS01"
          actual.secret_access_key.should eq "pC3z33ypXyiN3309kUykBriMkaKiADSodYZXJTKkCNc"
          actual.expiration.should eq Time.parse_iso8601 expiration
          reprovided = provider.credentials
          # Expired and regenerate session token
          actual.session_token.should_not eq reprovided.session_token
        ensure
          server[:server].close
        end
      end
    end
  end
end
