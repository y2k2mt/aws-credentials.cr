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
end
