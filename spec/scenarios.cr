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

  def self.scenario_sts
    uri = "/"
    expiration = "2019-05-31T23:28:33.359Z"
    xml = <<-STRING
    <AssumeRoleResponse xmlns="https://sts.amazonaws.com/doc/2011-06-15/">
      <AssumeRoleResult>
        <Credentials>
          <SessionToken>
           AQoDYXdzEPT//////////wEXAMPLEtc764bNrC9SAPBSM22wDOk4x4HIZ8j4FZTwdQW
           LWsKWHGBuFqwAeMicRXmxfpSPfIeoIYRqTflfKD8YUuwthAx7mSEI/qkPpKPi/kMcGd
           QrmGdeehM4IC1NtBmUpp2wUE8phUZampKsburEDy0KPkyQDYwT7WZ0wq5VSXDvp75YU
           9HFvlRd8Tx6q6fE8YQcHNVXAkiY9q6d+xo0rKwT38xVqr7ZD0u0iPPkUL64lIZbqBAz
           +scqKmlzm8FDrypNC9Yjc8fPOLn9FX9KSYvKTr4rvx3iSIlTJabIQwj2ICCR/oLxBA==
          </SessionToken>
          <SecretAccessKey>
           wJalrXUtnFEMI/K7MDENG/bPxRfiCYzEXAMPLEKEY
          </SecretAccessKey>
          <Expiration>#{expiration}</Expiration>
          <AccessKeyId>ASIAIOSFODNN7EXAMPLE</AccessKeyId>
        </Credentials>
        <AssumedRoleUser>
          <Arn>arn:aws:sts::123456789012:assumed-role/demo/Bob</Arn>
          <AssumedRoleId>ARO123EXAMPLE123:Bob</AssumedRoleId>
        </AssumedRoleUser>
        <PackedPolicySize>6</PackedPolicySize>
      </AssumeRoleResult>
      <ResponseMetadata>
        <RequestId>c6104cbe-af31-11e0-8154-cbc7ccf896c7</RequestId>
      </ResponseMetadata>
    </AssumeRoleResponse>
    STRING
    server = ServerStub.server ->(context : HTTP::Server::Context) {
      if context.request.path == uri
        context.response.content_type = "application/xml"
        context.response.print xml
      else
        context.response.status_code = 404
      end
    }
    {server, uri, expiration}
  end

  def self.scenario_sts_invalid
    uri = "/"
    expiration = "2019-05-31T23:28:33.359Z"
    xml = <<-STRING
    <AssumeRoleResponse xmlns="https://sts.amazonaws.com/doc/2011-06-15/">
    </AssumeRoleResponse>
    STRING
    server = ServerStub.server ->(context : HTTP::Server::Context) {
      if context.request.path == uri
        context.response.content_type = "application/xml"
        context.response.print xml
      else
        context.response.status_code = 404
      end
    }
    {server, uri, expiration}
  end
end
