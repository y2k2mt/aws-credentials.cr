require "http"
require "http/client"

module Aws::Credentials
  module HTTPClient
    def self.get(uri : URI, maybe_headers : HTTP::Headers? = nil)
      http = HTTP::Client.new uri
      begin
        http.connect_timeout = 5.seconds
        maybe_headers.try do |headers|
          http.headers = headers
        end
        http.get uri.path || raise "Missin URL path"
      ensure
        http.close
      end
    end

    def self.exec(uri : URI, request : HTTP::Request)
      http = HTTP::Client.new uri
      begin
        http.connect_timeout = 5.seconds
        http.exec request
      ensure
        http.close
      end
    end
  end
end
