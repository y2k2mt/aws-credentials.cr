require "../../spec_helper"

module TestingFile
  def self.create_file
    credentials_file =
      <<-STRING
    [default]
    aws_access_key_id = AKIADOF9DSEEBQPE8RFN
    aws_secret_access_key = mVlfnFielado11Gr/8fd9FFtoTkqBaY/5Kcbt7s
    [production]
    aws_access_key_id = AKIAPADD0SEEBQGHTIU3N
    aws_secret_access_key = rdsoD921jIDad1Gr/8FO0FFtoTkqBaY/YYudo05
  STRING
    tempfile = File.tempfile("#{Random::Secure.hex(36)}")
    tempfile.puts credentials_file
    tempfile.flush
    tempfile
  end

  def self.invalid_format_file
    credentials_file =
      <<-STRING
    [default]
    aws_access_key_id = AKIADOF9DSEEBQPE8RFN
  STRING
    tempfile = File.tempfile("#{Random::Secure.hex(36)}")
    tempfile.puts credentials_file
    tempfile.flush
    tempfile
  end
end

module Aws::Credentials
  describe SharedCredentialFileProvider do
    describe "credentials" do
      it "resolve credentials from file" do
        file = TestingFile.create_file
        begin
          provider = SharedCredentialFileProvider.new(file_path: file.path)
          actual = provider.credentials
          actual.access_key_id.should eq "AKIADOF9DSEEBQPE8RFN"
          actual.secret_access_key.should eq "mVlfnFielado11Gr/8fd9FFtoTkqBaY/5Kcbt7s"
        ensure
          file.close
        end
      end
    end
    describe "credentials" do
      it "has invalid format" do
        file = TestingFile.invalid_format_file
        begin
          provider = SharedCredentialFileProvider.new(file_path: file.path)
          expect_raises(MissingCredentials) do
            provider.credentials
          end
        ensure
          file.close
        end
      end
    end
    describe "credentials" do
      it "resolve credentials from specific profile" do
        file = TestingFile.create_file
        begin
          provider = SharedCredentialFileProvider.new(file_path: file.path, profile: "production")
          actual = provider.credentials
          actual.access_key_id.should eq "AKIAPADD0SEEBQGHTIU3N"
          actual.secret_access_key.should eq "rdsoD921jIDad1Gr/8FO0FFtoTkqBaY/YYudo05"
        ensure
          file.close
        end
      end
    end
    describe "credentials?" do
      it "credentials not avairable in specific profile" do
        file = TestingFile.create_file
        begin
          provider = SharedCredentialFileProvider.new(file_path: file.path, profile: "notavairable")
          actual = provider.credentials?
          actual.should be_nil
        ensure
          file.close
        end
      end
    end
    describe "credentials" do
      it "credentials not avairable in specific profile" do
        file = TestingFile.create_file
        begin
          provider = SharedCredentialFileProvider.new(file_path: file.path, profile: "notavairable")
          expect_raises(MissingCredentials) do
            provider.credentials
          end
        ensure
          file.close
        end
      end
    end
    describe "refresh" do
      it "ensure nothing to do" do
        file = TestingFile.create_file
        begin
          provider = SharedCredentialFileProvider.new(file_path: file.path, profile: "notavairable")
          expect_raises(KeyError) do
            provider.refresh
          end
        ensure
          file.close
        end
      end
    end
  end
end
