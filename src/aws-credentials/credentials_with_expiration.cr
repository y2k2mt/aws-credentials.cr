module Aws::Credentials
  module CredentialsWithExpiration
    def unresolved_or_expired(maybe_resolved_credentials : Credentials?, current_time_provider : Proc(Time))
      return true unless credential = maybe_resolved_credentials
      credential.expiration.try { |exp|
        exp.to_unix <= current_time_provider.call.to_unix
      } || false
    end
  end
end
