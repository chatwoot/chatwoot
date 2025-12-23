require "spec_helper"
require "foreman/engine"
require "foreman/export/supervisord"
require "tmpdir"

describe Foreman::Export::Supervisord, :fakefs do
  let(:procfile)    { FileUtils.mkdir_p("/tmp/app"); write_procfile("/tmp/app/Procfile") }
  let(:formation)   { nil }
  let(:engine)      { Foreman::Engine.new(:formation => formation).load_procfile(procfile) }
  let(:options)     { Hash.new }
  let(:supervisord) { Foreman::Export::Supervisord.new("/tmp/init", engine, options) }

  before(:each) { load_export_templates_into_fakefs("supervisord") }
  before(:each) { allow(supervisord).to receive(:say) }

  it "exports to the filesystem" do
    write_env(".env", "FOO"=>"bar", "URL"=>"http://example.com/api?foo=bar&baz=1")
    supervisord.engine.load_env('.env')
    supervisord.export
    expect(File.read("/tmp/init/app.conf")).to eq(example_export_file("supervisord/app-alpha-1.conf"))
  end

  it "cleans up if exporting into an existing dir" do
    expect(FileUtils).to receive(:rm).with("/tmp/init/app.conf")
    supervisord.export
    supervisord.export
  end

  context "with concurrency" do
    let(:formation) { "alpha=2" }

    it "exports to the filesystem with concurrency" do
      supervisord.export
      expect(File.read("/tmp/init/app.conf")).to eq(example_export_file("supervisord/app-alpha-2.conf"))
    end
  end

end
