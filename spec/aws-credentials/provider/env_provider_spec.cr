require "../../spec_helper"

Spec.before_each do
  ENV["AWS_ACCESS_KEY_ID"] = nil
  ENV["AWS_SECRET_ACCESS_KEY"] = nil
end

module Aws::Credentials
  describe EnvProvider do
    describe "credentials" do
      it "resolve credentialss from env" do
        ENV["AWS_ACCESS_KEY_ID"] = "AKIAIEZLS3DOSUZ7RS01"
        ENV["AWS_SECRET_ACCESS_KEY"] = "pC3z33ypXyiN3309kUykBriMkaKiADSodYZXJTKkCNc"
        provider = EnvProvider.new
        actual = provider.credentials
        actual.access_key_id.should eq "AKIAIEZLS3DOSUZ7RS01"
        actual.secret_access_key.should eq "pC3z33ypXyiN3309kUykBriMkaKiADSodYZXJTKkCNc"
      end
    end
    describe "credentials" do
      it "credentialss not avairable in env" do
        provider = EnvProvider.new
        expect_raises(MissingCredentials) do
          pp provider.credentials
        end
      end
    end
    describe "credentials?" do
      it "credentialss not avairable in env" do
        provider = EnvProvider.new
        actual = provider.credentials?
        actual.should be_nil
      end
    end
  end
end
