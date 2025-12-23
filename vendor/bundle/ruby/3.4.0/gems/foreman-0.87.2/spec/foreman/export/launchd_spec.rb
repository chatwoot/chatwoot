require "spec_helper"
require "foreman/engine"
require "foreman/export/launchd"
require "tmpdir"

describe Foreman::Export::Launchd, :fakefs do
  let(:procfile) { FileUtils.mkdir_p("/tmp/app"); write_procfile("/tmp/app/Procfile") }
  let(:options)  { Hash.new }
  let(:engine)   { Foreman::Engine.new().load_procfile(procfile) }
  let(:launchd)  { Foreman::Export::Launchd.new("/tmp/init", engine, options) }

  before(:each) { load_export_templates_into_fakefs("launchd") }
  before(:each) { allow(launchd).to receive(:say) }

  it "exports to the filesystem" do
    launchd.export
    expect(File.read("/tmp/init/app-alpha-1.plist")).to eq(example_export_file("launchd/launchd-a.default"))
    expect(File.read("/tmp/init/app-bravo-1.plist")).to eq(example_export_file("launchd/launchd-b.default"))
  end

  context "with multiple command arguments" do
    let(:procfile) { FileUtils.mkdir_p("/tmp/app"); write_procfile("/tmp/app/Procfile", "charlie") }

    it "splits each command argument" do
      launchd.export
      expect(File.read("/tmp/init/app-alpha-1.plist")).to eq(example_export_file("launchd/launchd-c.default"))
    end

  end

end
