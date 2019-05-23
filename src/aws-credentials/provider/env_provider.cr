module Aws::Credentials
  class EnvProvider
    include Provider

    def credentials : Credentials
      Credentials.new(
        access_key_id: ENV["AWS_ACCESS_KEY_ID"],
        secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
        session_token: ENV["AWS_SESSION_TOKEN"]?,
      )
    rescue e
      raise MissingCredentials.new e
    end
  end
end
