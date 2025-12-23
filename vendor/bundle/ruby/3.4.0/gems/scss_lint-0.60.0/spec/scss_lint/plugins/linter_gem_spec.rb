require 'spec_helper'

module SCSSLint
  describe Plugins::LinterGem do
    let(:subject) { described_class.new('a_gem') }

    describe '#load' do
      let(:gem_dir) { '/gem_dir' }
      let(:config_file) { File.join(gem_dir, '.scss-lint.yml') }
      let(:config_file_exists) { false }

      before do
        File.stub(:exist?).with(config_file).and_return(config_file_exists)
      end

      context 'when the gem does not exist' do
        it 'raises an exception' do
          expect { subject.load }.to raise_error Exceptions::PluginGemLoadError
        end
      end

      context 'when the gem exists' do
        before do
          subject.stub(:require).with('a_gem').and_return(true)
          Gem::Specification.stub(:find_by_name)
                            .with('a_gem')
                            .and_return(double(gem_dir: gem_dir))
        end

        it 'requires the gem' do
          subject.should_receive(:require).with('a_gem').once
          subject.load
        end

        context 'when the gem does not include a configuration file' do
          it 'loads an empty configuration' do
            subject.load
            subject.config.should == Config.new({})
          end
        end

        context 'when a config file exists in the gem' do
          let(:config_file_exists) { true }
          let(:fake_config) { Config.new('linters' => { 'FakeLinter' => {} }) }

          before do
            Config.should_receive(:load)
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
  end
end
