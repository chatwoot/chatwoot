require "spec_helper"
require "foreman/engine"
require "foreman/export/daemon"
require "tmpdir"

describe Foreman::Export::Daemon, :fakefs do
  let(:procfile)  { write_procfile("/tmp/app/Procfile") }
  let(:formation) { nil }
  let(:engine)    { Foreman::Engine.new(:formation => formation).load_procfile(procfile) }
  let(:options)   { Hash.new }
  let(:daemon)   { Foreman::Export::Daemon.new("/tmp/init", engine, options) }

  before(:each) { load_export_templates_into_fakefs("daemon") }
  before(:each) { allow(daemon).to receive(:say) }

  it "exports to the filesystem" do
    daemon.export

    expect(File.read("/tmp/init/app.conf")).to         eq(example_export_file("daemon/app.conf"))
    expect(File.read("/tmp/init/app-alpha.conf")).to   eq(example_export_file("daemon/app-alpha.conf"))
    expect(File.read("/tmp/init/app-alpha-1.conf")).to eq(example_export_file("daemon/app-alpha-1.conf"))
    expect(File.read("/tmp/init/app-bravo.conf")).to   eq(example_export_file("daemon/app-bravo.conf"))
    expect(File.read("/tmp/init/app-bravo-1.conf")).to eq(example_export_file("daemon/app-bravo-1.conf"))
  end

  it "cleans up if exporting into an existing dir" do
    expect(FileUtils).to receive(:rm).with("/tmp/init/app.conf")
    expect(FileUtils).to receive(:rm).with("/tmp/init/app-alpha.conf")
    expect(FileUtils).to receive(:rm).with("/tmp/init/app-alpha-1.conf")
    expect(FileUtils).to receive(:rm).with("/tmp/init/app-bravo.conf")
    expect(FileUtils).to receive(:rm).with("/tmp/init/app-bravo-1.conf")
    expect(FileUtils).to receive(:rm).with("/tmp/init/app-foo-bar.conf")
    expect(FileUtils).to receive(:rm).with("/tmp/init/app-foo-bar-1.conf")
    expect(FileUtils).to receive(:rm).with("/tmp/init/app-foo_bar.conf")
    expect(FileUtils).to receive(:rm).with("/tmp/init/app-foo_bar-1.conf")

    daemon.export
    daemon.export
  end

  it "does not delete exported files for similarly named applications" do
    FileUtils.mkdir_p "/tmp/init"

    ["app2", "app2-alpha", "app2-alpha-1"].each do |name|
      path = "/tmp/init/#{name}.conf"
      FileUtils.touch(path)
      expect(FileUtils).to_not receive(:rm).with(path)
    end

    daemon.export
  end

  context "with a formation" do
    let(:formation) { "alpha=2" }

    it "exports to the filesystem with concurrency" do
      daemon.export

      expect(File.read("/tmp/init/app.conf")).to            eq(example_export_file("daemon/app.conf"))
      expect(File.read("/tmp/init/app-alpha.conf")).to      eq(example_export_file("daemon/app-alpha.conf"))
      expect(File.read("/tmp/init/app-alpha-1.conf")).to    eq(example_export_file("daemon/app-alpha-1.conf"))
      expect(File.read("/tmp/init/app-alpha-2.conf")).to    eq(example_export_file("daemon/app-alpha-2.conf"))
      expect(File.exists?("/tmp/init/app-bravo-1.conf")).to eq(false)
    end
  end

  context "with alternate templates" do
    let(:template) { "/tmp/alternate" }
    let(:options)  { { :app => "app", :template => template } }

    before do
      FileUtils.mkdir_p template
      File.open("#{template}/master.conf.erb", "w") { |f| f.puts "alternate_template" }
    end

    it "can export with alternate template files" do
      daemon.export
      expect(File.read("/tmp/init/app.conf")).to eq("alternate_template\n")
    end
  end

  context "with alternate templates from home dir" do

    before do
      FileUtils.mkdir_p File.expand_path("~/.foreman/templates/daemon")
      File.open(File.expand_path("~/.foreman/templates/daemon/master.conf.erb"), "w") do |file|
        file.puts "default_alternate_template"
      end
    end

    it "can export with alternate template files" do
      daemon.export
      expect(File.read("/tmp/init/app.conf")).to eq("default_alternate_template\n")
    end
  end

end
