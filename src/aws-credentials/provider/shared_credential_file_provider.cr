require "ini"

module Aws::Credentials
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
      if !@config
        refresh
      end
      Credentials.new(
        access_key_id: @config.not_nil!["aws_access_key_id"],
        secret_access_key: @config.not_nil!["aws_secret_access_key"],
        session_token: @config.not_nil!["aws_session_token"]?
      )
    rescue e
      raise MissingCredentials.new e
    end

    def refresh : Nil
      @config = load
    end

    private def load : Hash(String, String)
      file_content = File.read(@file_path)
      INI.parse(file_content)[@profile]
    end
  end
end
