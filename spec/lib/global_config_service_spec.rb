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

      it 'replaces a seeded false value with the environment value' do
        config = InstallationConfig.find_or_initialize_by(name: 'ENABLE_ACCOUNT_SIGNUP')
        config.update!(value: false, locked: false)

        with_modified_env ENABLE_ACCOUNT_SIGNUP: 'true' do
          expect(described_class.load('ENABLE_ACCOUNT_SIGNUP', 'false')).to eq('true')
          expect(config.reload.value).to eq('true')
        end
      end

      it 'preserves an explicitly false database value without an environment override' do
        config = InstallationConfig.find_or_initialize_by(name: 'ENABLE_ACCOUNT_SIGNUP')
        config.update!(value: false, locked: false)

        with_modified_env ENABLE_ACCOUNT_SIGNUP: nil do
          expect(described_class.load('ENABLE_ACCOUNT_SIGNUP', 'true')).to be(false)
          expect(config.reload.value).to be(false)
        end
      end

      it 'preserves an intentionally blank database value without an environment override' do
        config = InstallationConfig.find_or_initialize_by(name: 'SLACK_CLIENT_ID')
        config.update!(value: '', locked: false)

        with_modified_env SLACK_CLIENT_ID: nil do
          expect(described_class.load('SLACK_CLIENT_ID', 'TEST_CLIENT_ID')).to eq('')
          expect(config.reload.value).to eq('')
        end
      end

      it 'replaces a non-blank database value with the environment value' do
        config = InstallationConfig.find_or_initialize_by(name: 'ENABLE_ACCOUNT_SIGNUP')
        config.update!(value: 'true', locked: false)

        with_modified_env ENABLE_ACCOUNT_SIGNUP: 'false' do
          expect(described_class.load('ENABLE_ACCOUNT_SIGNUP', 'false')).to eq('false')
          expect(config.reload.value).to eq('false')
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
    end
  end
end
