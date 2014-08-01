require "spec_helper"

describe "terraform" do
  let(:facts) { default_test_facts }
  let(:default_params) do
    {
      :ensure  => "present",
      :version => "0.9.9"
    }
  end

  context "ensure => present" do
    let(:params)  { default_params }
    let(:command) {
      [
        "rm -rf /tmp/terraform* /tmp/0",
        # download the zip to tmp
        "curl http://dl.bintray.com/mitchellh/terraform/0.9.9_darwin_amd64.zip?direct > /tmp/terraform-v0.9.9.zip",
        # extract the zip to tmp spot
        "mkdir /tmp/terraform",
        "unzip -o /tmp/terraform-v0.9.9.zip -d /tmp/terraform",
        # blow away an existing version if there is one
        "rm -rf /test/boxen/terraform",
        # move the directory to the root
        "mv /tmp/terraform /test/boxen/terraform",
        # chown it
        "chown -R testuser /test/boxen/terraform"
      ].join(" && ")
    }

    it do
      should contain_exec("install terraform v0.9.9").with({
        :command => command,
        :unless  => "test -x /test/boxen/terraform/terraform && /test/boxen/terraform/terraform -v | grep '\\bv0.9.9\\b'",
        :user    => "testuser",

      })

      should contain_file("/test/boxen/env.d/terraform.sh")
    end

    context "linux" do
      let(:facts) { default_test_facts.merge(:operatingsystem => "Debian") }

      it do
        should_not contain_file("/test/boxen/env.d/terraform.sh")
      end
    end
  end

  context "ensure => absent" do
    let(:params) { default_params.merge(:ensure => "absent") }

    it do
      should contain_file("/test/boxen/terraform").with_ensure("absent")
    end
  end

  context "ensure => whatever" do
    let(:params) { default_params.merge(:ensure => "whatever") }

    it do
      expect {
        should contain_file("/test/boxen/terraform")
      }.to raise_error(Puppet::Error, /Ensure must be present or absent/)
    end
  end
end
