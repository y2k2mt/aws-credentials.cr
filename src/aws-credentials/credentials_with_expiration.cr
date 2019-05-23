module Aws::Credentials
  module CredentialsWithExpiration
    def unresolved_or_expired(maybe_resolved_credentials : Credentials?, current_time_provider : Proc(Time))
      if maybe_resolved_credentials == nil
        pp "aws-credentials: No Credential. Should be resolve"
        return true
      end
      exp = maybe_resolved_credentials.not_nil!.expiration
      if exp
        pp "aws-credentials: Expired. Should be resolve #{exp} <= #{current_time_provider.call}"
        exp.to_unix <= current_time_provider.call.to_unix
      else
        pp "aws-credentials: Never Expired"
        false
      end
    end
  end
end
