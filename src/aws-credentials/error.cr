module Aws::Credentials
  class MissingCredentials < Exception
    def initialize(message : String = "Missing credentials")
      super message
    end

    def initialize(exception : Exception)
      super "Missing credentials", exception
    end
  end
end
