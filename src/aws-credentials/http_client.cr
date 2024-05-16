require "http"
require "http/client"

module Aws::Credentials
  module HTTPClient
    def self.get(uri : URI, headers : HTTP::Headers? = nil)
      http = HTTP::Client.new uri
      begin
        http.connect_timeout = 5.seconds
        headers.try do |hdr|
          http.headers = hdr
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
