module Aws::Credentials
  module CredentialsWithExpiration
    def unresolved_or_expired(maybe_resolved_credentials : Credentials?, current_time_provider : Proc(Time))
      if maybe_resolved_credentials == nil
        return true
      end
      exp = maybe_resolved_credentials.not_nil!.expiration
      if exp
        exp.to_unix <= current_time_provider.call.to_unix
      else
        false
      end
    end
  end
end
