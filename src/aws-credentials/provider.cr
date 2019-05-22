module Aws::Credentials
  module Provider
    abstract def credentials : Credentials

    def credentials? : Credentials | MissingCredentials
      credentials
    rescue e
      case e
      when MissingCredentials
        e
      else
        MissingCredentials.new e
      end
    end

    def refresh : Nil
      # Never expired as default
    end
  end

  class Providers
    include Provider

    @credential : Credentials? = nil
    @missing_credential : MissingCredentials? = nil

    def initialize(@providers : Array(Provider))
    end

    def credentials : Credentials
      if !@credential
        @credential = resolve_credentials
      end
      @credential.not_nil!
    end

    def credentials? : Credentials | MissingCredentials
      if @credential
        @credential.not_nil!
      elsif @missing_credential
        @missing_credential.not_nil!
      else
        maybe_credential = resolve_credentials?
        case maybe_credential
        when Credentials
          @credential = maybe_credential
          @credential.not_nil!
        else
          @missing_credential = maybe_credential
          @missing_credential.not_nil!
        end
      end
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
        case p.credentials?
        when Credentials
          true
        else
          false
        end
      }.try &.credentials? || MissingCredentials.new
    end

    def refresh : Nil
      @providers.each { |p| p.refresh }
      @credential = nil
    end
  end
end
