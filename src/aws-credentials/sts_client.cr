require "http"

module Aws::Credentials
  class STSClient
    def initialize(
      @signer : Proc(HTTP::Request, HTTP::Request)
    )
    end

    def assume_role(
      @role_arn : String,
      @role_session_name : String,
      @duration_seconds : Time::Span?,
      @policy : JSON::Any?
    ) : Credentials
      #TODO : implement
      raise MissingCredentials.new "Not implemented yet"
    end
  end
end
