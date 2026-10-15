require 'rails_helper'

describe Whatsapp::CatalogMessagePayloadBuilder do
  subject(:payload) { described_class.new(body: body, catalog: catalog).perform }

  let(:body) { 'Check these options' }
  let(:kind) { 'carousel' }
  let(:header) { nil }
  let(:footer) { nil }
  let(:items) do
    [
      { 'retailer_id' => 'sku-a', 'name' => 'Product A', 'section' => 'Section one' },
      { 'retailer_id' => 'sku-b', 'name' => 'Product B', 'section' => 'Section two' },
      { 'retailer_id' => 'sku-c', 'name' => 'Product C', 'section' => 'Section one' }
    ]
  end
  let(:catalog) { { 'kind' => kind, 'catalog_id' => 'cat-123', 'header' => header, 'footer' => footer, 'items' => items } }

  describe 'carousel' do
    it 'builds one product card per item without header or footer' do
      expect(payload).to eq(
        type: 'carousel',
        body: { text: 'Check these options' },
        action: {
          cards: [
            { card_index: 0, type: 'product', action: { product_retailer_id: 'sku-a', catalog_id: 'cat-123' } },
            { card_index: 1, type: 'product', action: { product_retailer_id: 'sku-b', catalog_id: 'cat-123' } },
            { card_index: 2, type: 'product', action: { product_retailer_id: 'sku-c', catalog_id: 'cat-123' } }
          ]
        }
      )
    end

    context 'when it has fewer than 2 products' do
      let(:items) { [{ 'retailer_id' => 'sku-a' }] }

      it { expect { payload }.to raise_error(described_class::Error, 'carousel requires between 2 and 10 products') }
    end

    context 'when it has more than 10 products' do
      let(:items) { Array.new(11) { |i| { 'retailer_id' => "sku-#{i}" } } }

      it { expect { payload }.to raise_error(described_class::Error, 'carousel requires between 2 and 10 products') }
    end

    context 'when the body is blank' do
      let(:body) { '' }

      it { expect { payload }.to raise_error(described_class::Error, 'carousel requires a body') }
    end

    context 'when the body is longer than 1024 characters' do
      let(:body) { 'a' * 1025 }

      it { expect { payload }.to raise_error(described_class::Error, 'The body must be at most 1024 characters long') }
    end
  end

  describe 'product' do
    let(:kind) { 'product' }
    let(:items) { [{ 'retailer_id' => 'sku-a' }] }

    it 'builds a single product message without body or footer when absent' do
      expect(described_class.new(body: nil, catalog: catalog).perform).to eq(
        type: 'product',
        action: { catalog_id: 'cat-123', product_retailer_id: 'sku-a' }
      )
    end

    context 'when body and footer are present' do
      let(:footer) { 'Free shipping' }

      it 'includes them' do
        expect(payload).to eq(
          type: 'product',
          body: { text: 'Check these options' },
          footer: { text: 'Free shipping' },
          action: { catalog_id: 'cat-123', product_retailer_id: 'sku-a' }
        )
      end
    end

    context 'when it has more than one product' do
      let(:items) { [{ 'retailer_id' => 'sku-a' }, { 'retailer_id' => 'sku-b' }] }

      it { expect { payload }.to raise_error(described_class::Error, 'product requires between 1 and 1 products') }
    end

    context 'when the footer is longer than 60 characters' do
      let(:footer) { 'a' * 61 }

      it { expect { payload }.to raise_error(described_class::Error, 'The footer must be at most 60 characters long') }
    end
  end

  describe 'product_list' do
    let(:kind) { 'product_list' }
    let(:header) { 'Our catalog' }

    it 'groups products by section keeping the order' do
      expect(payload).to eq(
        type: 'product_list',
        header: { type: 'text', text: 'Our catalog' },
        body: { text: 'Check these options' },
        action: {
          catalog_id: 'cat-123',
          sections: [
            { title: 'Section one', product_items: [{ product_retailer_id: 'sku-a' }, { product_retailer_id: 'sku-c' }] },
            { title: 'Section two', product_items: [{ product_retailer_id: 'sku-b' }] }
          ]
        }
      )
    end

    context 'when a footer is present' do
      let(:footer) { 'Prices in USD' }

      it { expect(payload[:footer]).to eq(text: 'Prices in USD') }
    end

    context 'when it has more than 30 products' do
      let(:items) { Array.new(31) { |i| { 'retailer_id' => "sku-#{i}", 'section' => 'All' } } }

      it { expect { payload }.to raise_error(described_class::Error, 'product_list requires between 1 and 30 products') }
    end

    context 'when the header is blank' do
      let(:header) { nil }

      it { expect { payload }.to raise_error(described_class::Error, 'product_list requires a header') }
    end

    context 'when the header is longer than 60 characters' do
      let(:header) { 'a' * 61 }

      it { expect { payload }.to raise_error(described_class::Error, 'The header must be at most 60 characters long') }
    end

    context 'when the body is blank' do
      let(:body) { nil }

      it { expect { payload }.to raise_error(described_class::Error, 'product_list requires a body') }
    end

    context 'when a section title is longer than 24 characters' do
      let(:items) { [{ 'retailer_id' => 'sku-a', 'section' => 'a' * 25 }] }

      it { expect { payload }.to raise_error(described_class::Error, 'The section must be at most 24 characters long') }
    end
  end

  describe 'validation common to all formats' do
    context 'when the catalog ID is missing' do
      let(:catalog) { { 'kind' => 'carousel', 'items' => items } }

      it { expect { payload }.to raise_error(described_class::Error, 'Catalog ID is required') }
    end

    context 'when a product has no retailer ID' do
      let(:items) { [{ 'retailer_id' => 'sku-a' }, { 'retailer_id' => '' }] }

      it { expect { payload }.to raise_error(described_class::Error, 'Every product requires a retailer ID (SKU)') }
    end

    context 'when the kind is unknown' do
      let(:kind) { 'grid' }

      it { expect { payload }.to raise_error(described_class::Error, 'Unsupported catalog message kind: grid') }
    end
  end
end
