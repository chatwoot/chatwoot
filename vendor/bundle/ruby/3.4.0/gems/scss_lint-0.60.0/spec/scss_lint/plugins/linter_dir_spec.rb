require 'spec_helper'

describe SCSSLint::Plugins::LinterDir do
  let(:plugin_directory) { File.expand_path('../fixtures/plugins', __dir__) }
  let(:subject) { described_class.new(plugin_directory) }

  describe '#load' do
    let(:config_file) { File.join(plugin_directory, '.scss-lint.yml') }
    let(:config_file_exists) { false }

    before do
      File.stub(:exist?).with(config_file).and_return(config_file_exists)
    end

    it 'requires each file in the plugin directory' do
      subject.should_receive(:require)
             .with(File.join(plugin_directory, 'linter_plugin.rb')).once

      subject.load
    end

    context 'when the dir does not include a configuration file' do
      it 'loads an empty configuration' do
        subject.load
        subject.config.should == SCSSLint::Config.new({})
      end
    end

    context 'when a config file exists in the dir' do
      let(:config_file_exists) { true }
      let(:fake_config) { SCSSLint::Config.new('linters' => { 'FakeLinter' => {} }) }

      before do
        SCSSLint::Config.should_receive(:load)
                        .with(config_file, merge_with_default: false)
                        .and_return(fake_config)
      end

      it 'loads the configuration' do
        subject.load
        subject.config.should == fake_config
      end
    end
  end
end
