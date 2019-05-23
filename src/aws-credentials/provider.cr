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

    def initialize(@providers : Array(Provider))
    end

    def credentials : Credentials
      resolve_credentials
    end

    def credentials? : Credentials | MissingCredentials
      resolve_credentials?
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
    end
  end
end
