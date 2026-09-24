require 'rails_helper'

RSpec.describe Shopify::ShopDomain do
  describe '.valid?' do
    it 'accepts valid Shopify domains' do
      expect(described_class.valid?('store.myshopify.com')).to be(true)
      expect(described_class.valid?('my-store.myshopify.io')).to be(true)
      expect(described_class.valid?('a.myshopify.com')).to be(true)
    end

    it 'rejects domains with a trailing hyphen in the shop label' do
      expect(described_class.valid?('bad-.myshopify.com')).to be(false)
    end
  end
end
