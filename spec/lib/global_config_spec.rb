require 'rails_helper'

describe GlobalConfig do
  subject(:trigger) { described_class }

  describe 'execute' do
    context 'when called with default options' do
      before do
        described_class.clear_cache
      end

      it 'hit DB for the first call' do
        expect(InstallationConfig).to receive(:find_by)
        described_class.get('test')
      end

      it 'get from cache for subsequent calls' do
        # this loads from DB
        described_class.get('test')

        # subsequent calls should not hit DB
        expect(InstallationConfig).not_to receive(:find_by)
        described_class.get('test')
      end

      it 'clears cache and fetch from DB next time, when clear_cache is called' do
        # this loads from DB and is cached
        described_class.get('test')

        # clears the cache
        described_class.clear_cache

        # should be loaded from DB
        expect(InstallationConfig).to receive(:find_by).with({ name: 'test' }).and_return(nil)
        described_class.get('test')
      end
    end
  end

  describe '.get_value' do
    let(:cache_key) { 'PRIMARY_COLOR_HEX' }

    before do
      described_class.clear_cache
      InstallationConfig.where(name: cache_key).delete_all
      create(:installation_config, name: cache_key, value: '#2781F6', locked: false)
    end

    it 'returns the seeded primary color hex value' do
      expect(described_class.get_value(cache_key)).to eq('#2781F6')
    end
  end
end
