require 'rails_helper'

RSpec.describe Whatsapp::CatalogMessageService do
  subject(:message) { described_class.new(conversation: conversation, sender: agent, params: params).perform }

  let(:whatsapp_channel) do
    create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
  end
  let(:inbox) { whatsapp_channel.inbox }
  let(:conversation) { create(:conversation, account: inbox.account, inbox: inbox) }
  let(:agent) { create(:user, account: inbox.account, role: :agent) }
  let(:kind) { 'carousel' }
  let(:header) { nil }
  let(:products) do
    Array.new(3) do |index|
      {
        retailer_id: "sku-#{index}", name: "Producto #{index}", price: '$10', image_urls: ["https://example.com/#{index}.jpg"],
        description: 'Descripcion', url: "https://example.com/p/#{index}", section: 'Cuadros'
      }
    end
  end
  let(:params) do
    { kind: kind, content: 'Mira estas opciones', header: header, footer: 'Picnic Art', catalog_id: 'cat-123', products: products }
      .with_indifferent_access
  end

  before { create(:inbox_member, inbox: inbox, user: agent) }

  context 'with a carousel' do
    it 'creates one outgoing message with the body as content and the catalog as attribute' do
      expect { message }.to change { conversation.messages.count }.by(1)

      expect(message).to be_outgoing
      expect(message.content).to eq('Mira estas opciones')
      expect(message.content_attributes['whatsapp_catalog']).to include(
        'kind' => 'carousel', 'catalog_id' => 'cat-123', 'footer' => 'Picnic Art'
      )
      expect(message.content_attributes['whatsapp_catalog']['items'].pluck('retailer_id')).to eq(%w[sku-0 sku-1 sku-2])
      expect(message.content_attributes['whatsapp_catalog']['items'].first).to include(
        'name' => 'Producto 0', 'price' => '$10', 'image_urls' => ['https://example.com/0.jpg'], 'section' => 'Cuadros'
      )
    end

    context 'with more than 10 products' do
      let(:products) { Array.new(11) { |index| { retailer_id: "sku-#{index}" } } }

      it 'raises and creates no message' do
        expect { message }.to raise_error(Whatsapp::CatalogMessagePayloadBuilder::Error, /between 2 and 10/)
        expect(conversation.messages.count).to eq(0)
      end
    end

    context 'without a body' do
      let(:params) { { kind: kind, catalog_id: 'cat-123', products: products }.with_indifferent_access }

      it 'raises' do
        expect { message }.to raise_error(Whatsapp::CatalogMessagePayloadBuilder::Error, /requires a body/)
      end
    end
  end

  context 'with a single product' do
    let(:kind) { 'product' }
    let(:products) { [{ retailer_id: 'sku-0', name: 'Producto 0' }] }

    it 'creates the product message' do
      expect(message.content_attributes['whatsapp_catalog']['kind']).to eq('product')
      expect(message.content_attributes['whatsapp_catalog']['items'].size).to eq(1)
    end

    context 'with two products' do
      let(:products) { [{ retailer_id: 'sku-0' }, { retailer_id: 'sku-1' }] }

      it 'raises' do
        expect { message }.to raise_error(Whatsapp::CatalogMessagePayloadBuilder::Error, /between 1 and 1/)
      end
    end
  end

  context 'with a product list' do
    let(:kind) { 'product_list' }
    let(:header) { 'Nuestros cuadros' }

    it 'creates the product list message' do
      expect(message.content_attributes['whatsapp_catalog']).to include('kind' => 'product_list', 'header' => 'Nuestros cuadros')
    end

    context 'without a header' do
      let(:header) { nil }

      it 'raises' do
        expect { message }.to raise_error(Whatsapp::CatalogMessagePayloadBuilder::Error, /requires a header/)
      end
    end

    context 'with more than 30 products' do
      let(:products) { Array.new(31) { |index| { retailer_id: "sku-#{index}", section: 'Cuadros' } } }

      it 'raises' do
        expect { message }.to raise_error(Whatsapp::CatalogMessagePayloadBuilder::Error, /between 1 and 30/)
      end
    end
  end

  context 'with a product without retailer ID' do
    let(:products) { [{ retailer_id: 'sku-0' }, { name: 'Sin SKU' }] }

    it 'raises' do
      expect { message }.to raise_error(Whatsapp::CatalogMessagePayloadBuilder::Error, /retailer ID/)
    end
  end
end
