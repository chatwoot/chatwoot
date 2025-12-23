require "spec_helper"
require "foreman/engine"
require "foreman/export/runit"
require "tmpdir"

describe Foreman::Export::Runit, :fakefs do
  let(:procfile) { FileUtils.mkdir_p("/tmp/app"); write_procfile("/tmp/app/Procfile", 'bar=baz') }
  let(:engine)   { Foreman::Engine.new(:formation => "alpha=2,bravo=1").load_procfile(procfile) }
  let(:options)  { Hash.new }
  let(:runit)    { Foreman::Export::Runit.new('/tmp/init', engine, options) }

  before(:each) { load_export_templates_into_fakefs("runit") }
  before(:each) { allow(runit).to receive(:say) }
  before(:each) { allow(FakeFS::FileUtils).to receive(:chmod) }

  it "exports to the filesystem" do
    engine.env["BAR"] = "baz"
    runit.export

    expect(File.read("/tmp/init/app-alpha-1/run")).to      eq(example_export_file('runit/app-alpha-1/run'))
    expect(File.read("/tmp/init/app-alpha-1/log/run")).to  eq(example_export_file('runit/app-alpha-1/log/run'))
    expect(File.read("/tmp/init/app-alpha-1/env/PORT")).to eq("5000\n")
    expect(File.read("/tmp/init/app-alpha-1/env/BAR")).to  eq("baz\n")
    expect(File.read("/tmp/init/app-alpha-2/run")).to      eq(example_export_file('runit/app-alpha-2/run'))
    expect(File.read("/tmp/init/app-alpha-2/log/run")).to  eq(example_export_file('runit/app-alpha-2/log/run'))
    expect(File.read("/tmp/init/app-alpha-2/env/PORT")).to eq("5001\n")
    expect(File.read("/tmp/init/app-alpha-2/env/BAR")).to  eq("baz\n")
    expect(File.read("/tmp/init/app-bravo-1/run")).to      eq(example_export_file('runit/app-bravo-1/run'))
    expect(File.read("/tmp/init/app-bravo-1/log/run")).to  eq(example_export_file('runit/app-bravo-1/log/run'))
    expect(File.read("/tmp/init/app-bravo-1/env/PORT")).to eq("5100\n")
  end

  it "creates a full path to the export directory" do
    expect { runit.export }.to_not raise_error
  end
end
