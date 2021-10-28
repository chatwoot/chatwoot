require 'rails_helper'

describe GlobalConfigService do
  subject(:trigger) { described_class }

  describe 'execute' do
    context 'when called with default options' do
      before do
        GlobalConfig.clear_cache
      end

      it 'set default value if not found on db nor env var' do
        described_class.load('ENABLE_ACCOUNT_SIGNUP', 'true')
        value = GlobalConfig.get('ENABLE_ACCOUNT_SIGNUP')
        expect(value).to be 'true'
      end

      it 'get value from env variable if not found on DB' do
        with_modified_env ENABLE_ACCOUNT_SIGNUP: 'false' do
          GlobalConfig.clear_cache
          described_class.load('ENABLE_ACCOUNT_SIGNUP', 'true')
          expect(value).to be 'false'
        end
      end

      it 'get value from DB if found' do
        # Not clearing the GlobalConfig and as such its value should
        # be `false` in the DB from the test above
        described_class.load('ENABLE_ACCOUNT_SIGNUP', 'true')
        expect(value).to be 'false'
      end
    end
  end
end
