module Aws::Credentials
  module Provider
    abstract def credentials : Credentials

    def credentials? : Credentials?
      credentials
    rescue e
      nil
    end

    def refresh : Nil
      # Never expired at default
    end
  end

  class Providers
    include Provider
    include CredentialsWithExpiration

    @resolved : Credentials? = nil

    def initialize(
      @providers : Array(Provider),
      @current_time_provider : Proc(Time) = ->{ Time.now }
    )
    end

    def credentials : Credentials
      if unresolved_or_expired @resolved, @current_time_provider
        refresh
        @resolved = resolve_credentials
      end
      @resolved.not_nil!
    end

    private def resolve_credentials : Credentials
      maybe_found = resolve_credentials?
      case maybe_found
      when Credentials
        maybe_found
      else
        raise maybe_found
      end
    end

    private def resolve_credentials? : Credentials | MissingCredentials
      @providers.find { |p|
        p.credentials? ? true : false
      }.try &.credentials? || MissingCredentials.new "No provider serves credential : #{@providers.map { |p| p.class.name }}"
    end

    def refresh : Nil
      @providers.each do |p|
        p.refresh
      rescue
        # Nothing to do
      end

      @resolved = nil
    end
  end
end
