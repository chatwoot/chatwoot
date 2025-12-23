require 'spec_helper'

describe SCSSLint::Runner do
  let(:config_options) do
    {
      'linters' => {
        'FakeLinter1' => { 'enabled' => true },
        'FakeLinter2' => { 'enabled' => false },
      },
    }
  end

  let(:config) { SCSSLint::Config.new(config_options) }
  let(:runner) { described_class.new(config) }

  before do
    SCSSLint::LinterRegistry.stub(:linters)
                            .and_return([SCSSLint::Linter::FakeLinter1,
                                         SCSSLint::Linter::FakeLinter2])
  end

  class SCSSLint::Linter::FakeLinter1 < SCSSLint::Linter; end
  class SCSSLint::Linter::FakeLinter2 < SCSSLint::Linter; end

  describe '#run' do
    let(:files) { [{ path: 'dummy1.scss' }, { path: 'dummy2.scss' }] }
    subject     { runner.run(files) }

    before do
      SCSSLint::Engine.stub(:new)
      SCSSLint::Linter.any_instance.stub(:run)
    end

    it 'searches for lints in each file' do
      runner.should_receive(:find_lints).exactly(files.size).times
      subject
    end

    context 'when all linters are disabled' do
      let(:config_options) do
        {
          'linters' => {
            'FakeLinter1' => { 'enabled' => false },
            'FakeLinter2' => { 'enabled' => false },
          },
        }
      end

      before do
        SCSSLint::Linter.any_instance
                        .stub(:run)
                        .and_raise(RuntimeError.new('Linter#run was called'))
      end

      it 'never runs a linter' do
        expect { subject }.to_not raise_error
      end
    end

    context 'when the engine raises a FileEncodingError' do
      let(:error) do
        SCSSLint::FileEncodingError.new('File encoding error!')
      end

      before do
        SCSSLint::Engine.stub(:new).and_raise(error)
        subject
      end

      it 'records the error as an Encoding lint' do
        expect(runner.lints).to(
          be_all { |lint| lint.linter.is_a?(SCSSLint::Linter::Encoding) }
        )
      end

      it 'records the error with the error message' do
        expect(runner.lints).to(
          be_all { |lint| lint.description == error.message }
        )
      end
    end

    context 'when the engine raises a Sass::SyntaxError' do
      let(:error) do
        Sass::SyntaxError.new('Syntax error!', line: 42)
      end

      before do
        SCSSLint::Engine.stub(:new).and_raise(error)
        subject
      end

      it 'records the error as a Syntax lint' do
        expect(runner.lints).to(
          be_all { |lint| lint.linter.is_a?(SCSSLint::Linter::Syntax) }
        )
      end

      it 'records the error with the error message' do
        expect(runner.lints).to(
          be_all { |lint| lint.description == "Syntax Error: #{error.message}" }
        )
      end

      it 'records the error with the line number' do
        expect(runner.lints).to(be_all { |lint| lint.location.line == 42 })
      end
    end

    context 'when files ere excluded for one linter' do
      let(:config_options) do
        {
          'linters' => {
            'FakeLinter1' => { 'enabled' => true,
                               'exclude' => [File.expand_path('dummy1.scss'),
                                             File.expand_path('dummy2.scss')] },
            'FakeLinter2' => { 'enabled' => false },
          },
        }
      end

      before do
        SCSSLint::Linter::FakeLinter1.any_instance
                                     .stub(:run)
                                     .and_raise(RuntimeError.new('FakeLinter1#run was called'))
      end

      it 'does not run the linter for the disabled files' do
        expect { subject }.to_not raise_error
      end
    end

    context 'when a linter raises an error' do
      let(:backtrace) { %w[file.rb:1 file.rb:2] }

      let(:error) do
        StandardError.new('Some error message').tap do |e|
          e.set_backtrace(backtrace)
        end
      end

      before do
        runner.stub(:run_linter).and_raise(error)
      end

      it 'raises a LinterError' do
        expect { subject }.to raise_error(SCSSLint::Exceptions::LinterError)
      end

      it 'has the name of the file the linter was checking' do
        expect { subject }.to(raise_error { |e| e.message.should include files.first[:path] })
      end

      it 'has the same backtrace as the original error' do
        expect { subject }.to(raise_error { |e| e.backtrace.should == backtrace })
      end
    end
  end
end
