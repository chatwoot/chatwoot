require 'rails_helper'

RSpec.describe Shopify::CustomApp do
  let(:account) { create(:account) }
  let(:install_url) { 'https://admin.shopify.com/oauth/install_custom_app?client_id=test-client&signature=test-signature' }
  let(:custom_app) do
    described_class.new(
      account: account, shop_domain: 'test-store.myshopify.com', client_id: 'test-client',
      client_secret: 'test-secret', install_url: install_url, enabled: false
    )
  end

  describe 'installation URL validation' do
    it 'accepts the Shopify-generated link without a store path' do
      custom_app.valid?

      expect(custom_app.errors[:install_url]).to be_empty
    end

    it 'accepts the existing store-specific link' do
      custom_app.install_url = install_url.sub('/oauth/', '/store/test-store/oauth/')
      custom_app.valid?

      expect(custom_app.errors[:install_url]).to be_empty
    end

    {
      'another host' => ['admin.shopify.com', 'example.com'],
      'an HTTP link' => ['https:', 'http:'],
      'another store path' => ['/oauth/', '/store/another-store/oauth/'],
      'another endpoint' => ['/install_custom_app', '/authorize'],
      'a mismatched client ID' => ['client_id=test-client', 'client_id=another-client'],
      'a missing client ID' => ['client_id=test-client&', ''],
      'a missing signature' => ['&signature=test-signature', ''],
      'an empty signature' => ['signature=test-signature', 'signature=']
    }.each do |description, (original, replacement)|
      it "rejects #{description}" do
        custom_app.install_url = install_url.sub(original, replacement)
        custom_app.valid?

        expect(custom_app.errors[:install_url]).to include('must be the Shopify-generated install link for this app and store')
      end
    end
  end
end
