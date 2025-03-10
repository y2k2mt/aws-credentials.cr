require "../spec_helper"

module Aws::Credentials
  # Returns the most simple credentials that never expire
  class ProviderA
    include Provider

    def initialize
      @logger = ::Log.for("ProviderA")
    end

    def credentials : Credentials
      Credentials.new(
        access_key_id: "ACCESSKEY_A",
        secret_access_key: "SECRET_A",
      )
    end
  end

  # Returns temporary credentials
  class ProviderB
    include Provider

    def initialize
      @logger = ::Log.for("ProviderB")
    end

    def credentials : Credentials
      Credentials.new(
        access_key_id: "ACCESSKEY_B",
        secret_access_key: "SECRET_B",
        session_token: Random::Secure.hex(16),
        expiration: Time.utc + 15.minutes,
      )
    end
  end

  # Never returns any credentials
  class ProviderC
    include Provider

    def initialize
      @logger = ::Log.for("ProviderC")
    end

    def credentials : Credentials
      raise MissingCredentials.new "ERR"
    end
  end

  # Never returns any credentials and is also unable to refresh itself
  class ProviderD
    include Provider

    def initialize
      @logger = ::Log.for("ProviderD")
    end

    def credentials : Credentials
      raise Exception.new "ERR"
    end

    def refresh
      raise Exception.new "REFRESH ERR"
    end
  end

  # Returns different credentials if they have expired
  # Allows playing around with time to avoid additional waiting
  class ProviderE
    include Provider

    setter current_time
    setter expiration

    def initialize(@current_time : Time)
      @expiration = Time.parse_iso8601("2019-05-21T00:00:00Z")
      @logger = ::Log.for("ProviderE")
    end

    def credentials : Credentials
      if @expiration.to_unix > @current_time.to_unix
        Credentials.new(
          access_key_id: "ACCESSKEY_E1",
          secret_access_key: "SECRET_E1",
          session_token: Random::Secure.hex(16),
          expiration: @expiration
        )
      else
        Credentials.new(
          access_key_id: "ACCESSKEY_E2",
          secret_access_key: "SECRET_E2",
          session_token: Random::Secure.hex(16),
          expiration: @expiration
        )
      end
    end
  end
end

module Aws::Credentials
  describe Providers do
    it "resolve credentials from A" do
      provider = Providers.new([ProviderA.new, ProviderB.new, ProviderC.new] of Provider)
      actual = provider.credentials
      actual.access_key_id.should eq("ACCESSKEY_A")
      actual.secret_access_key.should eq("SECRET_A")
    end

    it "resolve credentials from B" do
      provider = Providers.new([ProviderC.new, ProviderB.new, ProviderA.new] of Provider)
      actual = provider.credentials
      actual.access_key_id.should eq("ACCESSKEY_B")
      actual.secret_access_key.should eq("SECRET_B")
      reprovided = provider.credentials
      actual.should eq reprovided
    end

    it "unresolve credentials" do
      provider = Providers.new([ProviderC.new, ProviderC.new, ProviderC.new] of Provider)
      actual = provider.credentials?
      actual.should be_nil
    end

    it "unresolve credentials with other exception" do
      provider = Providers.new([ProviderC.new, ProviderC.new, ProviderD.new] of Provider)
      actual = provider.credentials?
      actual.should be_nil
    end

    it "doesn't refresh when the credentials have not expired" do
      current = Time.parse_iso8601("2019-05-20T00:00:00Z")
      e = ProviderE.new(current)
      provider = Providers.new(
        providers: [e] of Provider,
        current_time_provider: -> { current },
      )
      actual = provider.credentials
      actual.access_key_id.should eq "ACCESSKEY_E1"

      current2 = Time.parse_iso8601("2019-05-20T23:00:00Z")
      e.current_time = current2
      provider.current_time_provider = -> { current2 }
      reprovided = provider.credentials
      # NOT expired and expects same
      actual.hash.should eq(reprovided.hash)
    end

    it "refreshes when the credentials have expired" do
      current = Time.parse_iso8601("2019-05-20T23:00:00Z")
      e = ProviderE.new(current)
      provider = Providers.new(
        providers: [e] of Provider,
        current_time_provider: -> { current },
      )
      actual = provider.credentials
      actual.access_key_id.should eq "ACCESSKEY_E1"

      current2 = Time.parse_iso8601("2019-05-21T01:00:00Z")
      e.current_time = current2
      e.expiration = Time.parse_iso8601("2019-05-22T00:00:00Z")
      provider.current_time_provider = -> { current2 }
      reprovided = provider.credentials
      # Expired and refreshed
      actual.hash.should_not eq(reprovided.hash)
    end

    it "resolve credentials from B after a refresh" do
      provider = Providers.new([ProviderC.new, ProviderB.new, ProviderA.new] of Provider)
      actual = provider.credentials
      actual.access_key_id.should eq("ACCESSKEY_B")
      actual.secret_access_key.should eq("SECRET_B")
      provider.refresh
      reprovided = provider.credentials
      actual.session_token.should_not eq(reprovided.session_token)
    end

    it "resolve credentials from B after a refresh with error" do
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
