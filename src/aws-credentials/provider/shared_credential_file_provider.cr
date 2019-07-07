require "ini"

module Aws::Credentials
  # Resolving credential from shared credential file.
  #
  # https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html
  class SharedCredentialFileProvider
    include Provider

    @config : Hash(String, String)? = nil

    def initialize(
      @file_path : String = ENV["AWS_SHARED_CREDENTIALS_FILE"]?.try { |e|
        File.expand_path e
      } || File.expand_path("~/.aws/credentials"),
      @profile : String = "default"
    )
    end

    def credentials : Credentials
      refresh unless @config
      @config.try { |conf|
        Credentials.new(
          access_key_id: conf["aws_access_key_id"],
          secret_access_key: conf["aws_secret_access_key"],
          session_token: conf["aws_session_token"]?
        )
      } || raise MissingCredentials.new "No Shared credential file loaded."
    rescue e
      raise MissingCredentials.new e
    end

    def refresh : Nil
      @config = load
    end

    private def load : Hash(String, String)
      file_content = File.read @file_path
      INI.parse(file_content)[@profile]
    end
  end
end
