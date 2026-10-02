require 'rails_helper'

RSpec.describe WebCrawling::ContextDev::Configuration do
  describe '.configured?' do
    it 'returns true when the shared Context.dev API key is present' do
      create(:installation_config, name: 'CONTEXT_DEV_API_KEY', value: 'context-test-key')

      expect(described_class.configured?).to be(true)
    end

    it 'returns false when the shared Context.dev API key is absent' do
      expect(described_class.configured?).to be(false)
    end
  end
end
