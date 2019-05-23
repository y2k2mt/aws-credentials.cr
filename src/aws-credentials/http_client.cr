require "http/client"

module Aws::Credentials
  module HTTPClient
    def self.get(uri : URI)
      http = HTTP::Client.new uri
      begin
        http.connect_timeout = 5.seconds
        http.get uri.path.not_nil!
      ensure
        http.close
      end
    end
  end
end
