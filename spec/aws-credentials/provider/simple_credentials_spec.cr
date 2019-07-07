require "../../spec_helper"

module Aws::Credentials
  describe SimpleCredentials do
    describe "credentials" do
      it "resolve credentials" do
        access_key_id = "AKIAIEZLS3DOSUZ7RS01"
        secret_access_key = "pC3z33ypXyiN3309kUykBriMkaKiADSodYZXJTKkCNc"
        provider = SimpleCredentials.new(
          access_key_id: access_key_id,
          secret_access_key: secret_access_key,
        )
        actual = provider.credentials
        actual.access_key_id.should eq "AKIAIEZLS3DOSUZ7RS01"
        actual.secret_access_key.should eq "pC3z33ypXyiN3309kUykBriMkaKiADSodYZXJTKkCNc"
        reresolved = provider.credentials
        actual.should eq(reresolved)
      end
    end
    describe "credentials" do
      it "credentials is expired" do
        current = Time.parse_iso8601 "2019-05-21T00:00:00Z"
        provider = SimpleCredentials.new(
          access_key_id: "ACCESS_KEY",
          secret_access_key: "SECRET_KEY",
          session_token: "SESSION_KEY",
          expiration: Time.parse_iso8601("2019-05-20T22:00:00Z"),
          current_time_provider: ->{ current },
        )
        expect_raises(MissingCredentials) do
          provider.credentials
        end
      end
    end
    describe "credentials" do
      it "credentials is not expired" do
        current = Time.parse_iso8601 "2019-05-20T00:00:00Z"
        expiration = Time.parse_iso8601("2019-05-20T22:00:00Z")
        provider = SimpleCredentials.new(
          access_key_id: "ACCESS_KEY",
          secret_access_key: "SECRET_KEY",
          session_token: "SESSION_KEY",
          expiration: expiration,
          current_time_provider: ->{ current },
        )
        actual = provider.credentials
        actual.access_key_id.should eq "ACCESS_KEY"
        actual.secret_access_key.should eq "SECRET_KEY"
        actual.session_token.should eq "SESSION_KEY"
        actual.expiration.should eq expiration
      end
    end
  end
end
