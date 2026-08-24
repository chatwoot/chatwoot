require 'rails_helper'

RSpec.describe Shopify::ShopDomain do
  describe '.normalize' do
    it 'normalizes case and surrounding whitespace without accepting a URL' do
      expect(described_class.normalize('  Acme-Store.MyShopify.Com  ')).to eq('acme-store.myshopify.com')
    end
  end

  describe '.valid?' do
    it 'accepts canonical tenant domains and rejects suffix confusion and URLs' do
      expect(described_class.valid?('acme-store.myshopify.com')).to be(true)
      expect(described_class.valid?('acme-store.myshopify.com.attacker.example')).to be(false)
      expect(described_class.valid?('https://acme-store.myshopify.com')).to be(false)
      expect(described_class.valid?('myshopify.com')).to be(false)
      expect(described_class.valid?('acme-.myshopify.com')).to be(false)
    end
  end
end
