require "../spec_helper"

module Aws::Credentials
  class ProviderA
    include Provider

    def credentials
      Credentials.new(
        access_key_id: "ACCESSKEY_A",
        secret_access_key: "SECRET_A",
      )
    end
  end

  class ProviderB
    include Provider

    def credentials
      Credentials.new(
        access_key_id: "ACCESSKEY_B",
        secret_access_key: "SECRET_B",
        session_token: Random::Secure.hex(16),
        expiration: Time.parse_iso8601 "2019-05-21T00:00:00Z"
      )
    end
  end

  class ProviderC
    include Provider

    def credentials
      raise MissingCredentials.new "ERR"
    end
  end

  class ProviderD
    include Provider

    def credentials
      raise Exception.new "ERR"
    end
  end
end

module Aws::Credentials
  describe Providers do
    describe "credentials" do
      it "resolve credentials from A" do
        provider = Providers.new([ProviderA.new, ProviderB.new, ProviderC.new] of Provider)
        actual = provider.credentials
        actual.access_key_id.should eq("ACCESSKEY_A")
        actual.secret_access_key.should eq("SECRET_A")
      end
    end
    describe "credentials" do
      it "resolve credentials from B" do
        provider = Providers.new([ProviderC.new, ProviderB.new, ProviderA.new] of Provider)
        actual = provider.credentials
        actual.access_key_id.should eq("ACCESSKEY_B")
        actual.secret_access_key.should eq("SECRET_B")
        reprovided = provider.credentials
        actual.session_token.should eq(reprovided.session_token)
      end
    end
    describe "credentials" do
      it "unresolve credentials" do
        provider = Providers.new([ProviderC.new, ProviderC.new, ProviderC.new] of Provider)
        actual = provider.credentials?
        actual.should be_a MissingCredentials
      end
    end
    describe "credentials" do
      it "unresolve credentials with other exception" do
        provider = Providers.new([ProviderC.new, ProviderC.new, ProviderD.new] of Provider)
        actual = provider.credentials?
        actual.should be_a MissingCredentials
      end
    end
    describe "refresh" do
      it "resolve credentials from B" do
        provider = Providers.new([ProviderC.new, ProviderB.new, ProviderA.new] of Provider)
        actual = provider.credentials
        actual.access_key_id.should eq("ACCESSKEY_B")
        actual.secret_access_key.should eq("SECRET_B")
        provider.refresh
        reprovided = provider.credentials
        actual.session_token.should_not eq(reprovided.session_token)
      end
    end
  end
end
