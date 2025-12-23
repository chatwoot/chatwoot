require "spec_helper"
require "foreman/engine"
require "foreman/export/systemd"
require "tmpdir"

describe Foreman::Export::Systemd, :fakefs, :aggregate_failures do
  let(:procfile)  { write_procfile("/tmp/app/Procfile") }
  let(:formation) { nil }
  let(:engine)    { Foreman::Engine.new(:formation => formation).load_procfile(procfile) }
  let(:options)   { Hash.new }
  let(:systemd)   { Foreman::Export::Systemd.new("/tmp/init", engine, options) }

  before(:each) { load_export_templates_into_fakefs("systemd") }
  before(:each) { allow(systemd).to receive(:say) }

  it "exports to the filesystem" do
    systemd.export

    expect(File.read("/tmp/init/app.target")).to eq(example_export_file("systemd/app.target"))
    expect(File.read("/tmp/init/app-alpha.1.service")).to eq(example_export_file("systemd/app-alpha.1.service"))
    expect(File.read("/tmp/init/app-bravo.1.service")).to eq(example_export_file("systemd/app-bravo.1.service"))
  end

  context "when systemd export was run using the previous version of systemd export" do
    before do
     write_file("/tmp/init/app.target")

     write_file("/tmp/init/app-alpha@.service")
     write_file("/tmp/init/app-alpha.target")
     write_file("/tmp/init/app-alpha.target.wants/app-alpha@5000.service")

     write_file("/tmp/init/app-bravo.target")
     write_file("/tmp/init/app-bravo@.service")
     write_file("/tmp/init/app-bravo.target.wants/app-bravo@5100.service")

     write_file("/tmp/init/app-foo_bar.target")
     write_file("/tmp/init/app-foo_bar@.service")
     write_file("/tmp/init/app-foo_bar.target.wants/app-foo_bar@5200.service")

     write_file("/tmp/init/app-foo-bar.target")
     write_file("/tmp/init/app-foo-bar@.service")
     write_file("/tmp/init/app-foo-bar.target.wants/app-foo-bar@5300.service")
    end

    it "cleans up service files created by systemd export" do
      expect(FileUtils).to receive(:rm).with("/tmp/init/app.target")

      expect(FileUtils).to receive(:rm).with("/tmp/init/app-alpha@.service")
      expect(FileUtils).to receive(:rm).with("/tmp/init/app-alpha.target")
      expect(FileUtils).to receive(:rm).with("/tmp/init/app-alpha.target.wants/app-alpha@5000.service")
      expect(FileUtils).to receive(:rm_r).with("/tmp/init/app-alpha.target.wants")

      expect(FileUtils).to receive(:rm).with("/tmp/init/app-bravo.target")
      expect(FileUtils).to receive(:rm).with("/tmp/init/app-bravo@.service")
      expect(FileUtils).to receive(:rm).with("/tmp/init/app-bravo.target.wants/app-bravo@5100.service")
      expect(FileUtils).to receive(:rm_r).with("/tmp/init/app-bravo.target.wants")

      expect(FileUtils).to receive(:rm).with("/tmp/init/app-foo_bar.target")
      expect(FileUtils).to receive(:rm).with("/tmp/init/app-foo_bar@.service")
      expect(FileUtils).to receive(:rm).with("/tmp/init/app-foo_bar.target.wants/app-foo_bar@5200.service")
      expect(FileUtils).to receive(:rm_r).with("/tmp/init/app-foo_bar.target.wants")

      expect(FileUtils).to receive(:rm).with("/tmp/init/app-foo-bar.target")
      expect(FileUtils).to receive(:rm).with("/tmp/init/app-foo-bar@.service")
      expect(FileUtils).to receive(:rm).with("/tmp/init/app-foo-bar.target.wants/app-foo-bar@5300.service")
      expect(FileUtils).to receive(:rm_r).with("/tmp/init/app-foo-bar.target.wants")

      systemd.export
    end
  end

  context "when systemd export was run using the current version of systemd export" do
    before do
      systemd.export
    end

    it "cleans up service files created by systemd export" do
      expect(FileUtils).to receive(:rm).with("/tmp/init/app.target")
      expect(FileUtils).to receive(:rm).with("/tmp/init/app-alpha.1.service")
      expect(FileUtils).to receive(:rm).with("/tmp/init/app-bravo.1.service")
      expect(FileUtils).to receive(:rm).with("/tmp/init/app-foo_bar.1.service")
      expect(FileUtils).to receive(:rm).with("/tmp/init/app-foo-bar.1.service")

      systemd.export
    end
  end

  it "includes environment variables" do
    engine.env['KEY'] = 'some "value"'
    systemd.export
    expect(File.read("/tmp/init/app-alpha.1.service")).to match(/KEY=some "value"/)
  end

  it "includes ExecStart line" do
    engine.env['KEY'] = 'some "value"'
    systemd.export
    expect(File.read("/tmp/init/app-alpha.1.service")).to match(/^ExecStart=/)
  end

  context "with a custom formation specified" do
    let(:formation) { "alpha=2" }

    it "exports only those services that are specified in the formation" do
      systemd.export

      expect(File.read("/tmp/init/app.target")).to include("Wants=app-alpha.1.service app-alpha.2.service\n")
      expect(File.read("/tmp/init/app-alpha.1.service")).to eq(example_export_file("systemd/app-alpha.1.service"))
      expect(File.read("/tmp/init/app-alpha.2.service")).to eq(example_export_file("systemd/app-alpha.2.service"))
      expect(File.exist?("/tmp/init/app-bravo.1.service")).to be_falsey
    end
  end

  context "with alternate template directory specified" do
    let(:template) { "/tmp/alternate" }
    let(:options)  { { :app => "app", :template => template } }

    before do
      FileUtils.mkdir_p template
      File.open("#{template}/master.target.erb", "w") { |f| f.puts "alternate_template" }
    end

    it "uses template files found in the alternate directory" do
      systemd.export
      expect(File.read("/tmp/init/app.target")).to eq("alternate_template\n")
    end

    context "with alternate templates in the user home directory" do
      before do
        FileUtils.mkdir_p File.expand_path("~/.foreman/templates/systemd")
        File.open(File.expand_path("~/.foreman/templates/systemd/master.target.erb"), "w") do |file|
          file.puts "home_dir_template"
        end
      end

      it "uses template files found in the alternate directory" do
        systemd.export
        expect(File.read("/tmp/init/app.target")).to eq("alternate_template\n")
      end
    end
  end

  context "with alternate templates in the user home directory" do
    before do
      FileUtils.mkdir_p File.expand_path("~/.foreman/templates/systemd")
      File.open(File.expand_path("~/.foreman/templates/systemd/master.target.erb"), "w") do |file|
        file.puts "home_dir_template"
      end
    end

    it "uses template files found in the user home directory" do
      systemd.export
      expect(File.read("/tmp/init/app.target")).to eq("home_dir_template\n")
    end
  end
end
