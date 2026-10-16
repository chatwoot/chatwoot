require 'rails_helper'

describe ConfigLoader do
  subject(:trigger) { described_class.new.process }

  describe 'execute' do
    context 'when called with default options' do
      it 'creates installation configs' do
        expect(InstallationConfig.count).to eq(0)
        subject
        expect(InstallationConfig.count).to be > 0
      end

      it 'creates account level feature defaults as entry on config table' do
        subject
        expect(InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')).to be_truthy
      end
    end

    context 'with reconcile_only_new option' do
      let(:class_instance) { described_class.new }
      let(:config) { { name: 'WHO', value: 'corona' } }
      let(:updated_config) { { name: 'WHO', value: 'covid 19' } }

      before do
        allow(described_class).to receive(:new).and_return(class_instance)
        allow(class_instance).to receive(:general_configs).and_return([config])
        described_class.new.process
      end

      it 'being true it should not update existing config value' do
        expect(InstallationConfig.find_by(name: 'WHO').value).to eq('corona')
        allow(class_instance).to receive(:general_configs).and_return([updated_config])
        described_class.new.process({ reconcile_only_new: true })
        expect(InstallationConfig.find_by(name: 'WHO').value).to eq('corona')
      end

      it 'updates the existing config value with new default value' do
        expect(InstallationConfig.find_by(name: 'WHO').value).to eq('corona')
        allow(class_instance).to receive(:general_configs).and_return([updated_config])
        described_class.new.process({ reconcile_only_new: false })
        expect(InstallationConfig.find_by(name: 'WHO').value).to eq('covid 19')
      end
    end

    it 'preserves feature flag column metadata in account level defaults' do
      Dir.mktmpdir do |config_path|
        File.write("#{config_path}/installation_config.yml", <<~YAML)
          - name: TEST_CONFIG
            value: test
            locked: true
        YAML
        File.write("#{config_path}/features.yml", <<~YAML)
          - name: extension_feature
            display_name: Extension Feature
            enabled: false
            column: feature_flags_ext_1
        YAML

        described_class.new.process(config_path: config_path)

        expect(InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS').value).to include(
          a_hash_including('name' => 'extension_feature', 'column' => 'feature_flags_ext_1')
        )
      end
    end
  end
end
