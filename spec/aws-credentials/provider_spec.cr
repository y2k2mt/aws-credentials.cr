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

    def refresh
      raise Exception.new "REFRESH ERR"
    end
  end

  class ProviderE
    include Provider

    setter current_time

    def initialize(@current_time : Time)
    end

    def credentials
      expiration = Time.parse_iso8601("2019-05-21T00:00:00Z")
      if expiration.to_unix < @current_time.to_unix
        Credentials.new(
          access_key_id: "ACCESSKEY_E1",
          secret_access_key: "SECRET_E1",
          session_token: Random::Secure.hex(16),
          expiration: expiration
        )
      else
        Credentials.new(
          access_key_id: "ACCESSKEY_E2",
          secret_access_key: "SECRET_E2",
          session_token: Random::Secure.hex(16),
          expiration: expiration
        )
      end
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
        actual.should_not eq reprovided
      end
    end
    describe "credentials" do
      it "unresolve credentials" do
        provider = Providers.new([ProviderC.new, ProviderC.new, ProviderC.new] of Provider)
        actual = provider.credentials?
        actual.should be_nil
      end
    end
    describe "credentials" do
      it "unresolve credentials with other exception" do
        provider = Providers.new([ProviderC.new, ProviderC.new, ProviderD.new] of Provider)
        actual = provider.credentials?
        actual.should be_nil
      end
    end
    describe "credentials" do
      it "expired and refresh credentials" do
        current = Time.parse_iso8601("2019-05-21T00:00:00Z")
        e = ProviderE.new(current)
        provider = Providers.new(
          providers: [e] of Provider,
          current_time_provider: ->{ Time.parse_iso8601("2019-05-20T23:00:00Z") },
        )
        actual = provider.credentials
        current2 = Time.parse_iso8601("2019-05-21T01:00:00Z")
        e.current_time = current2
        reprovided = provider.credentials
        # NOT expired and expects same
        actual.hash.should eq(reprovided.hash)
      end
    end
    describe "credentials" do
      it "expired and refresh credentials" do
        current = Time.parse_iso8601("2019-05-20T23:00:00Z")
        e = ProviderE.new(current)
        provider = Providers.new(
          providers: [e] of Provider,
          current_time_provider: ->{ Time.parse_iso8601("2019-05-21T00:00:00Z") },
        )
        actual = provider.credentials
        current2 = Time.parse_iso8601("2019-05-21T01:00:00Z")
        e.current_time = current2
        reprovided = provider.credentials
        # Expired and refreshed
        actual.hash.should_not eq(reprovided.hash)
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
    describe "refresh" do
      it "resolve credentials from B with error" do
        provider = Providers.new([ProviderD.new, ProviderB.new, ProviderA.new] of Provider)
        actual = provider.credentials
        actual.access_key_id.should eq("ACCESSKEY_B")
        actual.secret_access_key.should eq("SECRET_B")
        provider.refresh
        reprovided = provider.credentials
        reprovided.access_key_id.should eq("ACCESSKEY_B")
        reprovided.secret_access_key.should eq("SECRET_B")
        actual.session_token.should_not eq(reprovided.session_token)
      end
    end
  end
end
