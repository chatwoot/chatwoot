require 'spec_helper'

module SCSSLint
  describe Plugins do
    let(:subject) { described_class.new(Config.new(config_options, Config.user_file)) }

    describe '#load' do
      context 'when gem plugins are specified' do
        let(:config_options) { { 'plugin_gems' => ['a_gem'] } }
        let(:plugin) { double(load: nil) }

        before do
          Plugins::LinterGem.stub(:new).with('a_gem').and_return(plugin)
        end

        it 'loads the plugin' do
          plugin.should_receive(:load)
          subject.load
        end
      end

      context 'when directory plugins are specified' do
        let(:config_options) { { 'plugin_directories' => ['some_dir'] } }
        let(:plugin) { double(load: nil) }
        let(:plugin_dir) { File.join(File.dirname(Config.user_file), 'some_dir') }

        before do
          Plugins::LinterDir.stub(:new).with(plugin_dir).and_return(plugin)
        end

        it 'loads the plugin' do
          plugin.should_receive(:load)
          subject.load
        end
      end

      context 'when plugins options are empty lists' do
        let(:config_options) { { 'plugin_directories' => [], 'plugin_gems' => [] } }

        it 'returns empty array' do
          subject.load.should == []
        end
      end

      context 'when no plugins options are specified' do
        let(:config_options) { {} }

        it 'returns empty array' do
          subject.load.should == []
        end
      end
    end
  end
end
