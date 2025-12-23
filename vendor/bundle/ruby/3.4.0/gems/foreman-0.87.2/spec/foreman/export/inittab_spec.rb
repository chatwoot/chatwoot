require "spec_helper"
require "foreman/engine"
require "foreman/export/inittab"
require "tmpdir"

describe Foreman::Export::Inittab, :fakefs do
  let(:procfile)  { FileUtils.mkdir_p("/tmp/app"); write_procfile("/tmp/app/Procfile") }
  let(:location)  { "/tmp/inittab" }
  let(:formation) { nil }
  let(:engine)    { Foreman::Engine.new(:formation => formation).load_procfile(procfile) }
  let(:options)   { Hash.new }
  let(:inittab)   { Foreman::Export::Inittab.new(location, engine, options) }

  before(:each) { load_export_templates_into_fakefs("inittab") }
  before(:each) { allow(inittab).to receive(:say) }

  it "exports to the filesystem" do
    inittab.export
    expect(File.read("/tmp/inittab")).to eq(example_export_file("inittab/inittab.default"))
  end

  context "to stdout" do
    let(:location) { "-" }

    it "exports to stdout" do
      expect(inittab).to receive(:puts).with(example_export_file("inittab/inittab.default"))
      inittab.export
    end
  end

  context "with concurrency" do
    let(:formation) { "alpha=2" }

    it "exports to the filesystem with concurrency" do
      inittab.export
      expect(File.read("/tmp/inittab")).to eq(example_export_file("inittab/inittab.concurrency"))
    end
  end

end
