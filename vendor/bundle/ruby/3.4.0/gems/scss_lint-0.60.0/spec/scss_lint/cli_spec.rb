require 'spec_helper'
require 'scss_lint/cli'

describe SCSSLint::CLI do
  include_context 'isolated environment'

  let(:config_options) do
    {
      'linters' => {
        'FakeTestLinter1' => { 'enabled' => true },
        'FakeTestLinter2' => { 'enabled' => true },
      },
    }
  end

  let(:config) { SCSSLint::Config.new(config_options) }

  class SCSSLint::Linter::FakeTestLinter1 < SCSSLint::Linter; end
  class SCSSLint::Linter::FakeTestLinter2 < SCSSLint::Linter; end

  before do
    SCSSLint::Config.stub(:load)
                    .with(SCSSLint::Config::DEFAULT_FILE, merge_with_default: false)
                    .and_return(config)
    SCSSLint::LinterRegistry.stub(:linters)
                            .and_return([SCSSLint::Linter::FakeTestLinter1,
                                         SCSSLint::Linter::FakeTestLinter2])
  end

  describe '#run' do
    let(:files)  { ['file1.scss', 'file2.scss'] }
    let(:flags)  { [] }
    let(:io)     { StringIO.new }
    let(:output) { io.string }
    let(:logger) { SCSSLint::Logger.new(io) }
    subject      { SCSSLint::CLI.new(logger) }

    before do
      SCSSLint::FileFinder.any_instance.stub(:find).and_return(files)
      SCSSLint::Runner.any_instance.stub(:find_lints)
    end

    def safe_run
      subject.run(flags + files)
    rescue SystemExit
      # Keep running tests
    end

    context 'when passed the --color flag' do
      let(:flags) { ['--color'] }

      it 'sets the logger to output in color' do
        safe_run
        logger.color_enabled.should == true
      end

      context 'and the output stream is not a TTY' do
        before do
          io.stub(:tty?).and_return(false)
        end

        it 'sets the logger to output in color' do
          safe_run
          logger.color_enabled.should == true
        end
      end
    end

    context 'when passed the --no-color flag' do
      let(:flags) { ['--no-color'] }

      it 'sets the logger to not output in color' do
        safe_run
        logger.color_enabled.should == false
      end
    end

    context 'when --[no-]color flag is not specified' do
      before do
        io.stub(:tty?).and_return(tty)
      end

      context 'and the output stream is a TTY' do
        let(:tty) { true }

        it 'sets the logger to output in color' do
          safe_run
          logger.color_enabled.should == true
        end
      end

      context 'and the output stream is not a TTY' do
        let(:tty) { false }

        it 'sets the logger to not output in color' do
          safe_run
          logger.color_enabled.should == false
        end
      end
    end

    context 'when there are no lints' do
      before do
        SCSSLint::Runner.any_instance.stub(:lints).and_return([])
      end

      it 'returns a successful exit code' do
        safe_run.should == 0
      end

      it 'outputs nothing' do
        safe_run
        output.should be_empty
      end
    end

    context 'when there are only warnings' do
      before do
        SCSSLint::Runner.any_instance.stub(:lints).and_return([
          SCSSLint::Lint.new(
            SCSSLint::Linter::FakeTestLinter1.new,
            'some-file.scss',
            SCSSLint::Location.new(1, 1, 1),
            'Some description',
            :warning,
          ),
        ])
      end

      it 'returns a exit code indicating only warnings were reported' do
        safe_run.should == 1
      end

      it 'outputs the warnings' do
        safe_run
        output.should include 'Some description'
      end
    end

    context 'when there are errors' do
      before do
        SCSSLint::Runner.any_instance.stub(:lints).and_return([
          SCSSLint::Lint.new(
            SCSSLint::Linter::FakeTestLinter1.new,
            'some-file.scss',
            SCSSLint::Location.new(1, 1, 1),
            'Some description',
            :error,
          ),
        ])
      end

      it 'exits with an error status code' do
        safe_run.should == 2
      end

      it 'outputs the errors' do
        safe_run
        output.should include 'Some description'
      end
    end

    context 'when the runner raises an error' do
      let(:backtrace) { %w[file1.rb file2.rb] }
      let(:message) { 'Some error message' }

      let(:error) do
        StandardError.new(message).tap { |e| e.set_backtrace(backtrace) }
      end

      before { SCSSLint::Runner.stub(:new).and_raise(error) }

      it 'exits with an internal software error status code' do
        subject.should_receive(:halt).with(:software)
        safe_run
      end

      it 'outputs the error message' do
        safe_run
        output.should include message
      end

      it 'outputs the backtrace' do
        safe_run
        output.should include backtrace.join("\n")
      end

      it 'outputs a link to the issue tracker' do
        safe_run
        output.should include SCSSLint::BUG_REPORT_URL
      end
    end

    context 'when a required library is not found' do
      let(:flags) { ['--require', 'some_non_existent_library'] }

      before do
        Kernel.stub(:require).with('some_non_existent_library').and_raise(
          SCSSLint::Exceptions::RequiredLibraryMissingError
        )
      end

      it 'exits with an appropriate status code' do
        subject.should_receive(:halt).with(:unavailable)
        safe_run
      end
    end

    context 'when the --stdin-file-path argument is specified' do
      let(:flags) { ['--stdin-file-path', 'some-fake-file-path.scss'] }

      before do
        STDIN.stub(:read).and_return('// Nothing interesting')
      end

      it 'passes STDIN and the file path as a file tuple to the runner' do
        SCSSLint::Runner.any_instance.should_receive(:run)
                        .with([file: STDIN, path: 'some-fake-file-path.scss'])
        safe_run
      end
    end

    context 'when specified SCSS file globs match no files' do
      before do
        SCSSLint::FileFinder.any_instance.stub(:find)
                            .and_raise(SCSSLint::Exceptions::NoFilesError)
      end

      it 'exits with an appropriate status code' do
        subject.should_receive(:halt).with(:no_files)
        safe_run
      end
    end

    context 'when a config file is specified' do
      let(:flags) { ['--config', 'custom_config.yml'] }

      before do
        File.stub(:exist?).with('.scss-lint.yml').and_return(true)
        File.stub(:exist?).with(SCSSLint::Config.user_file).and_return(true)
      end

      it 'loads config from the specified file' do
        SCSSLint::Config.should_receive(:load).with('custom_config.yml').and_return(config)
        safe_run
      end
    end

    context 'when a config file exists in the current directory and home directory' do
      before do
        File.stub(:exist?).with('.scss-lint.yml').and_return(true)
        File.stub(:exist?).with(SCSSLint::Config.user_file).and_return(true)
      end

      it 'loads config from the current directory' do
        SCSSLint::Config.should_receive(:load).with('.scss-lint.yml').and_return(config)
        safe_run
      end
    end

    context 'when a config file exists only in the user home directory' do
      before do
        File.stub(:exist?).with('.scss-lint.yml').and_return(false)
        File.stub(:exist?).with(SCSSLint::Config.user_file).and_return(true)
      end

      it 'loads config from the home directory' do
        config_path = File.expand_path('.scss-lint.yml', Dir.home)
        SCSSLint::Config.should_receive(:load).with(config_path).and_return(config)
        safe_run
      end
    end
  end
end
