require 'rails_helper'

describe GlobalConfigService do
  subject(:trigger) { described_class }

  describe 'execute' do
    context 'when called with default options' do
      before do
        GlobalConfig.clear_cache
      end

      it 'get value from DB if found' do
        pending 'add some checks'
      end

      it 'get value from env variable if not found on DB' do
        pending 'add some checks'
      end

      it 'set default value if not found on db nor env var' do
        pending 'add some checks'
      end
    end
  end
end
