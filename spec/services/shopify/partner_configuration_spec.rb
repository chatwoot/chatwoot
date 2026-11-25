require 'rails_helper'

RSpec.describe Shopify::PartnerConfiguration do
  let(:valid_values) do
    {
      SHOPIFY_PARTNER_ORGANIZATION_ID: '123',
      SHOPIFY_PARTNER_APP_ID: 'gid://shopify/App/456',
      SHOPIFY_PARTNER_ACCESS_TOKEN: 'partner-token',
      SHOPIFY_PARTNER_API_VERSION: '2026-07'
    }
  end

  it 'accepts a complete Partner API configuration' do
    expect { described_class.validate_for_save!(valid_values) }.not_to raise_error
  end

  it 'allows the optional Partner credentials to remain unconfigured' do
    expect do
      described_class.validate_for_save!(SHOPIFY_PARTNER_API_VERSION: '2026-07')
    end.not_to raise_error
  end

  it 'rejects an incomplete Partner API configuration' do
    expect do
      described_class.validate_for_save!(valid_values.except(:SHOPIFY_PARTNER_ACCESS_TOKEN))
    end.to raise_error(Shopify::PartnerClient::ConfigurationError, 'SHOPIFY_PARTNER_ACCESS_TOKEN is required')
  end

  it 'rejects a malformed API version even when credentials are unconfigured' do
    expect do
      described_class.validate_for_save!(SHOPIFY_PARTNER_API_VERSION: 'latest')
    end.to raise_error(Shopify::PartnerClient::ConfigurationError, 'SHOPIFY_PARTNER_API_VERSION must use YYYY-MM format')
  end

  it 'rejects an API version with an impossible month' do
    expect do
      described_class.validate_for_save!(SHOPIFY_PARTNER_API_VERSION: '2026-13')
    end.to raise_error(Shopify::PartnerClient::ConfigurationError, 'SHOPIFY_PARTNER_API_VERSION must use YYYY-MM format')
  end
end
