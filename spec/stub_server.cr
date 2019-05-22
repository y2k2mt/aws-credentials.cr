require "http/server"

module ServerStub
  def self.server(fn : Proc(HTTP::Server::Context, Int32?))
    server = HTTP::Server.new do |context|
      fn.call context
    end
    port = Random.rand 40000..65535

    server.bind_tcp port
    spawn do
      server.listen
    end
    {server: server, port: port}
  end
end
