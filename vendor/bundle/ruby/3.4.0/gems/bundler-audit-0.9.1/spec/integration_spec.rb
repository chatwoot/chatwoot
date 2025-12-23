require 'spec_helper'

describe "bin/bundler-audit" do
  let(:name) { 'bundler-audit' }
  let(:path) do
    File.expand_path(File.join(File.dirname(__FILE__),'..','bin',name))
  end

  let(:command) { "#{path} version" }

  subject { sh(command) }

  it "must invoke the CLI class" do
    expect(subject).to eq("bundler-audit #{Bundler::Audit::VERSION}#{$/}")
  end
end

describe "bin/bundle-audit" do
  let(:name) { 'bundle-audit' }
  let(:path) do
    File.expand_path(File.join(File.dirname(__FILE__),'..','bin',name))
  end

  let(:command) { "#{path} version" }

  subject { sh(command) }

  it "must invoke the CLI class" do
    expect(subject).to eq("bundler-audit #{Bundler::Audit::VERSION}#{$/}")
  end
end
