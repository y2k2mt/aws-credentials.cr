require "spec"
require "../src/aws-credentials"
require "./scenarios"
require "./stub_server"

if ENV["SPEC_LOGS"]?
  Spec.before_each { Log.setup_from_env }
end
