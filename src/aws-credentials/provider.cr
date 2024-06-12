module Aws::Credentials
  module Provider
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

    def initialize(
      @providers : Array(Provider),
      @current_time_provider : Proc(Time) = ->{ Time.utc }
    )
    end

    def credentials : Credentials
      if unresolved_or_expired @resolved, @current_time_provider
        refresh
        @resolved = resolve_credentials
      end
      @resolved || raise MissingCredentials.new "No resolved credentials from #{@providers}"
    end

    private def resolve_credentials : Credentials
      @providers.find(&.credentials?).try(&.credentials?) ||
        raise MissingCredentials.new "No provider serves credential : #{@providers.map(&.class.name)}"
    end

    def refresh : Nil
      @providers.each(&.refresh) rescue nil
      @resolved = nil
    end
  end
end
