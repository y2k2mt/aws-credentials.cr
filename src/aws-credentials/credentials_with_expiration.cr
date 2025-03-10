module Aws::Credentials
  module CredentialsWithExpiration
    def unresolved_or_expired(maybe_resolved_credentials : Credentials?, current_time_provider : Proc(Time))
      return true unless maybe_resolved_credentials
      expired?(maybe_resolved_credentials, current_time_provider)
    end

    def expired?(credentials : Credentials, current_time_provider : Proc(Time))
      credentials.expiration.try { |exp|
        exp.to_unix <= current_time_provider.call.to_unix
      } || false
    end
  end
end
