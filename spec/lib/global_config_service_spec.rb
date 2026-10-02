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

      it 'applies the env value when the config row exists with a blank value' do
        create(:installation_config, name: 'BLANK_ENV_CONFIG', value: nil)

        with_modified_env BLANK_ENV_CONFIG: 'from-env' do
          expect(described_class.load('BLANK_ENV_CONFIG', 'default')).to eq 'from-env'
        end

        expect(InstallationConfig.find_by(name: 'BLANK_ENV_CONFIG').value).to eq 'from-env'
        expect(GlobalConfig.get('BLANK_ENV_CONFIG')['BLANK_ENV_CONFIG']).to eq 'from-env'
      end

      it 'does not write the default value over an existing blank row' do
        create(:installation_config, name: 'BLANK_DEFAULT_CONFIG', value: nil)

        expect(described_class.load('BLANK_DEFAULT_CONFIG', 'default')).to be_nil
        expect(InstallationConfig.find_by(name: 'BLANK_DEFAULT_CONFIG').value).to be_nil
      end

      it 'keeps a stored value over the env value' do
        create(:installation_config, name: 'STORED_CONFIG', value: 'from-db')

        with_modified_env STORED_CONFIG: 'from-env' do
          expect(described_class.load('STORED_CONFIG', nil)).to eq 'from-db'
        end

        expect(InstallationConfig.find_by(name: 'STORED_CONFIG').value).to eq 'from-db'
      end

      it 'keeps a stored boolean false over the env value' do
        create(:installation_config, name: 'FALSE_CONFIG', value: false)

        with_modified_env FALSE_CONFIG: 'true' do
          expect(described_class.load('FALSE_CONFIG', nil)).to be false
        end
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
