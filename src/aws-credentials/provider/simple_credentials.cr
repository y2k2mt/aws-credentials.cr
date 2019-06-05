module Aws::Credentials
  # Simply holds given credentials.
  class SimpleCredentials
    include Provider
    include CredentialsWithExpiration

    def initialize(
      access_key_id : String,
      secret_access_key : String,
      session_token : String? = nil,
      expiration : Time? = nil,
      @credentials : Credentials? = Credentials.new(
        access_key_id: access_key_id,
        secret_access_key: secret_access_key,
        session_token: session_token,
        expiration: expiration,
      ),
      @current_time_provider : Proc(Time) = ->{ Time.now }
    )
    end

    def credentials : Credentials
      if unresolved_or_expired @credentials, @current_time_provider
        raise MissingCredentials.new "No credentials avairable"
      else
        @credentials.not_nil!
      end
    end
  end
end
