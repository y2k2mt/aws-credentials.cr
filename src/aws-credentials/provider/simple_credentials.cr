module Aws::Credentials
  # Simply holds given credentials.
  class SimpleCredentials
    include Provider
    include CredentialsWithExpiration

    def initialize(
      @access_key_id : String,
      @secret_access_key : String,
      @session_token : String? = nil,
      @expiration : Time? = nil,
      @current_time_provider : Proc(Time) = ->{ Time.now }
    )
    end

    private def resolve_credentials : Credentials
      @credentials = Credentials.new(
        access_key_id: @access_key_id,
        secret_access_key: @secret_access_key,
        session_token: @session_token,
        expiration: @expiration,
      ) unless @credentials
      @credentials.not_nil!
    end

    def credentials : Credentials
      resolved = resolve_credentials
      if unresolved_or_expired resolved, @current_time_provider
        raise MissingCredentials.new "No credentials avairable"
      else
        resolved
      end
    end
  end
end
