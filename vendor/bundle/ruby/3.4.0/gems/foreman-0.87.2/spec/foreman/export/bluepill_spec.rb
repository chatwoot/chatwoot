require "spec_helper"
require "foreman/engine"
require "foreman/export/bluepill"
require "tmpdir"

describe Foreman::Export::Bluepill, :fakefs do
  let(:procfile)  { FileUtils.mkdir_p("/tmp/app"); write_procfile("/tmp/app/Procfile") }
  let(:formation) { nil }
  let(:engine)    { Foreman::Engine.new(:formation => formation).load_procfile(procfile) }
  let(:options)   { Hash.new }
  let(:bluepill)  { Foreman::Export::Bluepill.new("/tmp/init", engine, options) }

  before(:each) { load_export_templates_into_fakefs("bluepill") }
  before(:each) { allow(bluepill).to receive(:say) }

  it "exports to the filesystem" do
    bluepill.export
    expect(normalize_space(File.read("/tmp/init/app.pill"))).to eq(normalize_space(example_export_file("bluepill/app.pill")))
  end

  it "cleans up if exporting into an existing dir" do
    expect(FileUtils).to receive(:rm).with("/tmp/init/app.pill")

    bluepill.export
    bluepill.export
  end

  context "with a process formation" do
    let(:formation) { "alpha=2" }

    it "exports to the filesystem with concurrency" do
      bluepill.export
      expect(normalize_space(File.read("/tmp/init/app.pill"))).to eq(normalize_space(example_export_file("bluepill/app-concurrency.pill")))
    end
  end

end
