module Aws::Credentials
  struct Credentials
    getter access_key_id, secret_access_key, session_token, expiration

    def initialize(
      @access_key_id : String,
      @secret_access_key : String,
      @session_token : String? = nil,
      @expiration : Time? = nil
    )
    end
  end

  module CredentialsWithExpiration
    def unresolved_or_expired(maybe_resolved_credentials : Credentials?, current_time_provider : Proc(Time))
      maybe_resolved_credentials.try do |r|
        r.expiration.try do |exp|
          return exp.to_unix < current_time_provider.call.to_unix
        end || false
      end || true
    end
  end
end
