require 'rails_helper'

describe Whatsapp::Providers::WhatsappCloudCatalogService do
  let(:whatsapp_channel) do
    create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let(:conversation) { create(:conversation, inbox: whatsapp_channel.inbox) }
  let(:catalog) do
    {
      'kind' => 'product',
      'catalog_id' => 'catalog_1',
      'footer' => 'Today only',
      'items' => [{ 'retailer_id' => 'sku-1' }]
    }
  end
  let(:message) do
    create(:message, conversation: conversation, message_type: :outgoing, content: 'Take a look', inbox: whatsapp_channel.inbox,
                     content_attributes: { 'whatsapp_catalog' => catalog })
  end
  let(:catalog_url) { 'https://graph.facebook.com/v24.0/123456789/messages' }
  let(:response_headers) { { 'Content-Type' => 'application/json' } }
  let(:whatsapp_response) { { messages: [{ id: 'message_id' }] } }

  def stub_catalog_request(interactive)
    stub_request(:post, catalog_url)
      .with(body: { messaging_product: 'whatsapp', to: '+123456789', interactive: interactive, type: 'interactive' }.to_json)
      .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
  end

  describe '.perform' do
    it 'sends a product card with footer as an interactive message' do
      stub_catalog_request(
        type: 'product', body: { text: 'Take a look' }, footer: { text: 'Today only' },
        action: { catalog_id: 'catalog_1', product_retailer_id: 'sku-1' }
      )

      expect(described_class.perform(whatsapp_channel, '+123456789', message)).to eq 'message_id'
    end

    it 'sends a carousel' do
      items = [{ 'retailer_id' => 'sku-1' }, { 'retailer_id' => 'sku-2' }]
      message.update!(content_attributes: { 'whatsapp_catalog' => catalog.merge('kind' => 'carousel', 'items' => items) })
      stub_catalog_request(
        type: 'carousel', body: { text: 'Take a look' },
        action: {
          cards: [
            { card_index: 0, type: 'product', action: { product_retailer_id: 'sku-1', catalog_id: 'catalog_1' } },
            { card_index: 1, type: 'product', action: { product_retailer_id: 'sku-2', catalog_id: 'catalog_1' } }
          ]
        }
      )

      expect(described_class.perform(whatsapp_channel, '+123456789', message)).to eq 'message_id'
    end

    it 'sends a product list' do
      message.update!(content_attributes: {
                        'whatsapp_catalog' => catalog.merge('kind' => 'product_list', 'header' => 'Our picks',
                                                            'items' => [{ 'retailer_id' => 'sku-1', 'section' => 'Mugs' }])
                      })
      stub_catalog_request(
        type: 'product_list', header: { type: 'text', text: 'Our picks' }, body: { text: 'Take a look' }, footer: { text: 'Today only' },
        action: { catalog_id: 'catalog_1', sections: [{ title: 'Mugs', product_items: [{ product_retailer_id: 'sku-1' }] }] }
      )

      expect(described_class.perform(whatsapp_channel, '+123456789', message)).to eq 'message_id'
    end

    it 'marks the message as failed with the error returned by Meta' do
      stub_request(:post, catalog_url)
        .to_return(status: 400, body: { error: { message: 'Product not found in catalog' } }.to_json, headers: response_headers)

      expect(described_class.perform(whatsapp_channel, '+123456789', message)).to be_nil
      expect(message.reload.status).to eq 'failed'
      expect(message.external_error).to eq 'Product not found in catalog'
    end

    it 'marks the message as failed when the catalog is invalid' do
      message.update!(content_attributes: { 'whatsapp_catalog' => catalog.merge('catalog_id' => nil) })

      expect(described_class.perform(whatsapp_channel, '+123456789', message)).to be_nil
      expect(message.reload.status).to eq 'failed'
      expect(message.external_error).to eq 'Catalog ID is required'
    end

    it 'marks the message as failed instead of sending only the attachment when it has attachments' do
      message.attachments.create!(account_id: message.account_id, file_type: :image,
                                  file: { io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png' })

      expect(described_class.perform(whatsapp_channel, '+123456789', message)).to be_nil
      expect(message.reload.status).to eq 'failed'
      expect(message.external_error).to eq 'Catalog messages cannot include attachments'
      expect(a_request(:post, /graph\.facebook\.com/)).not_to have_been_made
    end
  end
end
