require "spec_helper"
require "foreman/engine"
require "foreman/export"

describe "Foreman::Export::Base", :fakefs do
  let(:procfile) { FileUtils.mkdir_p("/tmp/app"); write_procfile("/tmp/app/Procfile") }
  let(:location) { "/tmp/init" }
  let(:engine)   { Foreman::Engine.new().load_procfile(procfile) }
  let(:subject)  { Foreman::Export::Base.new(location, engine) }

  it "has a say method for displaying info" do
    expect(subject).to receive(:puts).with("[foreman export] foo")
    subject.send(:say, "foo")
  end

  it "raises errors as a Foreman::Export::Exception" do
    expect { subject.send(:error, "foo") }.to raise_error(Foreman::Export::Exception, "foo")
  end
end
