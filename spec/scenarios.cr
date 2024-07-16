# ameba:disable Lint/SpecFilename
require "json"

module Scenarios
  # Scenario for ContainerCredentialProvider
  def self.scenario_one
    relative_uri = "/v2/credentials/2bf9b4ff-70a8-4d84-9733-xxxx"
    ENV["AWS_CONTAINER_CREDENTIALS_RELATIVE_URI"] = relative_uri
    server = ServerStub.server ->(context : HTTP::Server::Context) {
      expiration = (Time.utc + 15.minutes).to_rfc3339
      json = {
        "AccessKeyId"     => "AKIAIEZLS3DOSUZ7RS01",
        "Expiration"      => expiration,
        "RoleArn"         => "TASK_ROLE_ARN",
        "SecretAccessKey" => "pC3z33ypXyiN3309kUykBriMkaKiADSodYZXJTKkCNc",
        "Token"           => Random::Secure.hex(32),
      }.to_json
      if context.request.path == relative_uri
        context.response.content_type = "application/json"
        context.response.print json
      else
        context.response.status_code = 404
      end
    }
    {server, relative_uri}
  end

  # Scenario for InstanceMetadataProvider
  def self.scenario_two
    uri = "/latest/meta-data/iam/security-credentials/"
    role_name = "TestRole"
    server = ServerStub.server ->(context : HTTP::Server::Context) {
      expiration = (Time.utc + 15.minutes).to_rfc3339
      json = {
        "AccessKeyId"     => "AKIAIEZLS3DOSUZ7RS01",
        "Expiration"      => expiration,
        "RoleArn"         => "TASK_ROLE_ARN",
        "SecretAccessKey" => "pC3z33ypXyiN3309kUykBriMkaKiADSodYZXJTKkCNc",
        "Token"           => Random::Secure.hex(32),
      }.to_json
      if context.request.path == uri
        context.response.print role_name
      elsif context.request.path == "#{uri}#{role_name}"
        context.response.content_type = "application/json"
        context.response.print json
      else
        context.response.status_code = 404
      end
    }
    {server, uri}
  end

  # Normal scenario for AssumeRole*Provider
  # The expiration can be configured, the default is 15 minutes
  def self.scenario_sts(ttl : Time::Span? = nil)
    uri = "/"
    ttl = 15.minutes unless ttl
    server = ServerStub.server ->(context : HTTP::Server::Context) {
      expiration = (Time.utc + ttl).to_rfc3339
      if context.request.path == uri
        body_params = context.request.body.try { |body| URI::Params.parse(body.gets_to_end) rescue nil }
        action = body_params.try(&.["Action"]?) ||
                 context.request.query_params["Action"]?
        case action
        when "AssumeRole"
          xml = self.sts_response(expiration, with_web_identity: false)
          context.response.content_type = "application/xml"
          context.response.print xml
        when "AssumeRoleWithWebIdentity"
          xml = self.sts_response(expiration, with_web_identity: true)
          context.response.content_type = "application/xml"
          context.response.print xml
        else
          context.response.status_code = 400
          context.response.print %[Missing "Action" form field]
        end
      else
        context.response.status_code = 404
      end
    }
    {server, uri}
  end

  # Invalid scenario for AssumeRole*Provider - empty response
  def self.scenario_sts_invalid
    uri = "/"
    xml = <<-STRING
    <AssumeRoleResponse xmlns="https://sts.amazonaws.com/doc/2011-06-15/">
    </AssumeRoleResponse>
    STRING
    server = ServerStub.server ->(context : HTTP::Server::Context) {
      if context.request.path == uri
        body_params = context.request.body.try { |body| URI::Params.parse(body.gets_to_end) rescue nil }
        action = body_params.try(&.["Action"]?) ||
                 context.request.query_params["Action"]?
        case action
        when "AssumeRole"
          context.response.content_type = "application/xml"
          xml = <<-STRING
          <AssumeRoleResponse xmlns="https://sts.amazonaws.com/doc/2011-06-15/">
          </AssumeRoleResponse>
          STRING
          context.response.print xml
        when "AssumeRoleWithWebIdentity"
          context.response.content_type = "application/xml"
          xml = <<-STRING
          <AssumeRoleWithWebIdentityResponse xmlns="https://sts.amazonaws.com/doc/2011-06-15/">
          </AssumeRoleWithWebIdentityResponse>
          STRING
          context.response.print xml
        else
          context.response.status_code = 400
          context.response.print %[Missing "Action" form field]
        end
      else
        context.response.status_code = 404
      end
    }
    {server, uri}
  end

  private def self.sts_response(expiration : String, with_web_identity : Bool = false)
    suffix = with_web_identity ? "WithWebIdentity" : ""

    <<-STRING
    <AssumeRole#{suffix}Response xmlns="https://sts.amazonaws.com/doc/2011-06-15/">
      <AssumeRole#{suffix}Result>
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
      </AssumeRole#{suffix}Result>
      <ResponseMetadata>
        <RequestId>c6104cbe-af31-11e0-8154-cbc7ccf896c7</RequestId>
      </ResponseMetadata>
    </AssumeRole#{suffix}Response>
    STRING
  end
end
