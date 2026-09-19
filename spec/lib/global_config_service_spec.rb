require 'rails_helper'

describe GlobalConfigService do
  subject(:trigger) { described_class }

  describe 'execute' do
    context 'when called with default options' do
      before do
        # to clear redis cache
        GlobalConfig.clear_cache
      end

      # it 'set default value if not found on db nor env var' do
      #   value = GlobalConfig.get('ENABLE_ACCOUNT_SIGNUP')
      #   expect(value['ENABLE_ACCOUNT_SIGNUP']).to eq nil

      #   described_class.load('ENABLE_ACCOUNT_SIGNUP', 'true')

      #   value = GlobalConfig.get('ENABLE_ACCOUNT_SIGNUP')
      #   expect(value['ENABLE_ACCOUNT_SIGNUP']).to eq 'true'
      #   expect(InstallationConfig.find_by(name: 'ENABLE_ACCOUNT_SIGNUP')&.value).to eq 'true'
      # end

      it 'get value from env variable even if present on DB' do
        with_modified_env ENABLE_ACCOUNT_SIGNUP: 'false' do
          expect(InstallationConfig.find_by(name: 'ENABLE_ACCOUNT_SIGNUP')&.value).to be_nil
          value = described_class.load('ENABLE_ACCOUNT_SIGNUP', 'true')
          expect(value).to eq 'false'
        end
      end

      # it 'get value from DB if found' do
      #   # Set a value in db first and make sure this value
      #   # is not respected even when load() method is called with
      #   # another value.
      #   InstallationConfig.where(name: 'ENABLE_ACCOUNT_SIGNUP').first_or_create(value: 'true')
      #   described_class.load('ENABLE_ACCOUNT_SIGNUP', 'false')
      #   value = GlobalConfig.get('ENABLE_ACCOUNT_SIGNUP')
      #   expect(value['ENABLE_ACCOUNT_SIGNUP']).to eq 'true'
      # end

      it 'serves a stored boolean false from cache without clearing other cached configs' do
        create(:installation_config, name: 'ENABLE_SHOPIFY_INTEGRATION', value: false)

        expect(described_class.load('ENABLE_SHOPIFY_INTEGRATION', 'false')).to be false

        GlobalConfig.get('ENABLE_ACCOUNT_SIGNUP')
        described_class.load('ENABLE_SHOPIFY_INTEGRATION', 'false')

        expect(InstallationConfig).not_to receive(:find_by)
        GlobalConfig.get('ENABLE_ACCOUNT_SIGNUP')
      end

      it 'does not clear cached configs when the config row already exists with a blank value' do
        create(:installation_config, name: 'BLANK_VALUE_CONFIG', value: nil)

        GlobalConfig.get('ENABLE_ACCOUNT_SIGNUP')
        described_class.load('BLANK_VALUE_CONFIG', 'false')

        expect(InstallationConfig).not_to receive(:find_by)
        GlobalConfig.get('ENABLE_ACCOUNT_SIGNUP')
      end

      it 'treats a stored empty string as unconfigured' do
        create(:installation_config, name: 'EMPTY_VALUE_CONFIG', value: '')

        expect(described_class.load('EMPTY_VALUE_CONFIG', nil)).to be_nil
      end

      it 'clears the stale cached blank when creating the config' do
        GlobalConfig.get('NEW_CONFIG')

        described_class.load('NEW_CONFIG', 'true')

        expect(GlobalConfig.get('NEW_CONFIG')['NEW_CONFIG']).to eq 'true'
      end
    end
  end
end
