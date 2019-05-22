require "json"

module Scenarios
  def self.scenario_one
    relative_uri = "/v2/credentials/2bf9b4ff-70a8-4d84-9733-xxxx"
    ENV["AWS_CONTAINER_CREDENTIALS_RELATIVE_URI"] = relative_uri
    expiration = "2019-05-20T12:00:00Z"
    json = ->{ {
      "AccessKeyId"     => "AKIAIEZLS3DOSUZ7RS01",
      "Expiration"      => expiration,
      "RoleArn"         => "TASK_ROLE_ARN",
      "SecretAccessKey" => "pC3z33ypXyiN3309kUykBriMkaKiADSodYZXJTKkCNc",
      "Token"           => Random::Secure.hex(32),
    }.to_json }
    server = ServerStub.server ->(context : HTTP::Server::Context) {
      if context.request.path == relative_uri
        context.response.content_type = "application/json"
        context.response.print json.call
      else
        context.response.status_code = 404
      end
    }
    {server, relative_uri, expiration}
  end

  def self.scenario_two
    uri = "/latest/meta-data/iam/security-credentials/"
    role_name = "TestRole"
    expiration = "2019-05-20T12:00:00Z"
    json = ->{ {
      "AccessKeyId"     => "AKIAIEZLS3DOSUZ7RS01",
      "Expiration"      => expiration,
      "RoleArn"         => "TASK_ROLE_ARN",
      "SecretAccessKey" => "pC3z33ypXyiN3309kUykBriMkaKiADSodYZXJTKkCNc",
      "Token"           => Random::Secure.hex(32),
    }.to_json }
    server = ServerStub.server ->(context : HTTP::Server::Context) {
      if context.request.path == uri
        context.response.print role_name
      elsif context.request.path == "#{uri}#{role_name}"
        context.response.content_type = "application/json"
        context.response.print json.call
      else
        context.response.status_code = 404
      end
    }
    {server, uri, expiration}
  end
end
