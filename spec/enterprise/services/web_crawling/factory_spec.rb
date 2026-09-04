require 'rails_helper'

RSpec.describe WebCrawling::Factory do
  describe '.build' do
    it 'preserves Firecrawl as the automatic provider when its key is configured' do
      create(:installation_config, name: 'CAPTAIN_FIRECRAWL_API_KEY', value: 'firecrawl-key')

      expect(described_class.build).to be_a(WebCrawling::Firecrawl::Spider)
    end

    it 'uses the native provider in automatic mode when Firecrawl is unavailable' do
      create(:installation_config, name: described_class::CONFIG_KEY, value: 'auto')

      expect(described_class.build).to be_a(WebCrawling::Native::Spider)
    end

    it 'builds the explicitly selected Context.dev provider' do
      create(:installation_config, name: described_class::CONFIG_KEY, value: 'context_dev')
      create(:installation_config, name: 'CONTEXT_DEV_API_KEY', value: 'context-key')

      expect(described_class.build).to be_a(WebCrawling::ContextDev::Spider)
    end

    it 'rejects an explicitly selected provider without its API key' do
      create(:installation_config, name: described_class::CONFIG_KEY, value: 'context_dev')

      expect { described_class.build }.to raise_error(
        described_class::ConfigurationError,
        "Web crawler provider 'context_dev' is not configured"
      )
    end
  end
end
