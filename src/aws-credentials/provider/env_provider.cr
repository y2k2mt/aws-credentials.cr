module Aws::Credentials
  # Resolving credential from environment variables.
  #
  # https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html
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
