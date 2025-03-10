require "log"

module Aws::Credentials
  module Provider
    @logger : Log = ::Log.for("AWS.Credentials.Provider")

    # Resolving `AWS::Credentials::Credentials`.
    #
    # Credential not resolvable then raise `Aws::Credentials||MissingCredentials` error.
    abstract def credentials : Credentials

    # Resolving `AWS::Credentials::Credentials`.
    #
    # Credential not resolvable then return `nil`
    def credentials? : Credentials?
      credentials
    rescue e
      @logger.trace do
        String.build do |io|
          io << "Unable to obtain credentials: #{e}"
          io << ", cause: #{e.cause}" if e.cause
        end
      end
      nil
    end

    # Clear cache and reload credential from source.
    def refresh : Nil
      # Never expired at default
    end
  end

  # `Providers` provides credentials from multiple `Provider` and holds until expiration of credential.
  #
  # Credential expiration is reached then reload credentials from given `Provider`s.
  class Providers
    include Provider
    include CredentialsWithExpiration

    @resolved : Credentials? = nil
    @logger : Log

    setter current_time_provider : Proc(Time)

    def initialize(
      @providers : Array(Provider),
      @current_time_provider : Proc(Time) = ->{ Time.utc },
      logger : Log = ::Log.for("AWS.Credentials")
    )
      @logger = logger.for({{ @type.name.split("::")[-1] }})
    end

    def credentials : Credentials
      creds = @resolved
      if !creds
        @logger.debug { "No credentials are available, resolving new credentials" }
      elsif expired?(creds, @current_time_provider)
        @logger.debug { "The credentials have expired, resolving new credentials" }
      else
        return creds
      end
      refresh

      @resolved = nil
      @providers.each do |provider_|
        if creds = provider_.credentials?
          next if expired?(creds, @current_time_provider)
          @logger.debug { "Found credentials with provider #{provider_.class.name}" }
          @resolved = creds
          break
        end
      end
      @resolved || raise MissingCredentials.new "No resolved credentials from #{@providers.map(&.class.name)}"
    end

    def refresh : Nil
      @providers.each(&.refresh) rescue nil
      @resolved = nil
    end
  end
end
