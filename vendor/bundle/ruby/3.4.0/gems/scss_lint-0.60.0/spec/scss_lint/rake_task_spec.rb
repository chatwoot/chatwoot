require 'spec_helper'
require 'scss_lint/rake_task'
require 'tempfile'

describe SCSSLint::RakeTask do
  before do
    STDOUT.stub(:write) # Silence console output
  end

  after(:each) do
    Rake::Task['scss_lint'].clear if Rake::Task.task_defined?('scss_lint')
  end

  let(:file) do
    Tempfile.new(%w[scss-file .scss]).tap do |f|
      f.write(scss)
      f.close
    end
  end

  def run_task
    Rake::Task[:scss_lint].tap do |t|
      t.reenable # Allows us to execute task multiple times
      t.invoke(file.path)
    end
  end

  context 'basic RakeTask' do
    before(:each) do
      SCSSLint::RakeTask.new
    end

    context 'when SCSS document is valid with no lints' do
      let(:scss) { '' }

      it 'does not call Kernel.exit' do
        expect { run_task }.not_to raise_error
      end
    end

    context 'when SCSS document is invalid' do
      let(:scss) { '.class {' }

      it 'calls Kernel.exit with the status code' do
        expect { run_task }.to raise_error SystemExit
      end
    end
  end

  context 'configured RakeTask with a config file' do
    let(:scss) { '' }

    let(:config_file) do
      config = Tempfile.new(%w[foo .yml])
      config.write('')
      config.close
      config.path
    end

    it 'passes config files to the CLI' do
      SCSSLint::RakeTask.new.tap do |t|
        t.config = config_file
      end

      cli = double(SCSSLint::CLI)
      SCSSLint::CLI.should_receive(:new) { cli }
      args = ['--config', config_file, file.path]
      cli.should_receive(:run).with(args) { 0 }

      expect { run_task }.not_to raise_error
    end
  end

  context 'configured RakeTask with args' do
    let(:scss) { '' }

    it 'passes args to the CLI' do
      formatter_args = ['--formatter', 'JSON']

      SCSSLint::RakeTask.new.tap do |t|
        t.args = formatter_args
      end

      cli = double(SCSSLint::CLI)
      SCSSLint::CLI.should_receive(:new) { cli }
      args = formatter_args + [file.path]
      cli.should_receive(:run).with(args) { 0 }

      expect { run_task }.not_to raise_error
    end
  end
end
