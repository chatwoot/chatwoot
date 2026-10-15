require 'rails_helper'

RSpec.describe 'Conversation Catalog Messages API', type: :request do
  let(:account) { create(:account) }
  let(:whatsapp_channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
  end
  let(:inbox) { whatsapp_channel.inbox }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:kind) { 'carousel' }
  let(:header) { nil }
  let(:catalog_id) { 'cat-123' }
  let(:products) do
    Array.new(3) do |index|
      {
        retailer_id: "sku-#{index}", name: "Producto #{index}", price: '$10', image_urls: ["https://example.com/#{index}.jpg"],
        description: 'Descripcion', url: "https://example.com/p/#{index}", section: 'Cuadros'
      }
    end
  end
  let(:params) { { kind: kind, content: 'Mira estas opciones', header: header, footer: 'Picnic Art', catalog_id: catalog_id, products: products } }
  let(:url) { api_v1_account_conversation_catalog_message_url(account_id: account.id, conversation_id: conversation.display_id) }

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      post url

      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when it is an authenticated agent with access to the conversation' do
    before { create(:inbox_member, inbox: inbox, user: agent) }

    def post_catalog
      post url, params: params, headers: agent.create_new_auth_token, as: :json
    end

    it 'creates a carousel message and returns it' do
      expect { post_catalog }.to change { conversation.messages.count }.by(1)

      expect(response).to have_http_status(:success)
      body = response.parsed_body
      expect(body['content']).to eq('Mira estas opciones')
      expect(body['message_type']).to eq(1)
      expect(body['content_attributes']['whatsapp_catalog']).to include('kind' => 'carousel', 'catalog_id' => 'cat-123')
      expect(body['content_attributes']['whatsapp_catalog']['items'].size).to eq(3)
    end

    context 'with a product' do
      let(:kind) { 'product' }
      let(:products) { [{ retailer_id: 'sku-0', name: 'Producto 0' }] }

      it 'creates the message' do
        post_catalog

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['content_attributes']['whatsapp_catalog']['kind']).to eq('product')
      end

      context 'with two products' do
        let(:products) { [{ retailer_id: 'sku-0' }, { retailer_id: 'sku-1' }] }

        it 'returns unprocessable entity' do
          post_catalog

          expect(response).to have_http_status(:unprocessable_entity)
          expect(conversation.messages.count).to eq(0)
        end
      end
    end

    context 'with a product list' do
      let(:kind) { 'product_list' }
      let(:header) { 'Nuestros cuadros' }

      it 'creates the message' do
        post_catalog

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['content_attributes']['whatsapp_catalog']['header']).to eq('Nuestros cuadros')
      end

      context 'without a header' do
        let(:header) { nil }

        it 'returns unprocessable entity' do
          post_catalog

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'with 31 products' do
        let(:products) { Array.new(31) { |index| { retailer_id: "sku-#{index}", section: 'Cuadros' } } }

        it 'returns unprocessable entity' do
          post_catalog

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context 'with 11 carousel products' do
      let(:products) { Array.new(11) { |index| { retailer_id: "sku-#{index}" } } }

      it 'returns unprocessable entity' do
        post_catalog

        expect(response).to have_http_status(:unprocessable_entity)
        expect(conversation.messages.count).to eq(0)
      end
    end

    context 'with an unknown kind' do
      let(:kind) { 'grid' }

      it 'returns unprocessable entity' do
        post_catalog

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'without catalog id' do
      let(:catalog_id) { nil }

      it 'returns unprocessable entity' do
        post_catalog

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when the inbox is not WhatsApp Cloud' do
      let(:inbox) { create(:inbox, account: account) }

      it 'returns unprocessable entity' do
        post_catalog

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq(I18n.t('errors.whatsapp.catalog.cloud_inbox_required'))
        expect(conversation.messages.count).to eq(0)
      end
    end

    context 'when the conversation belongs to another account' do
      let(:other_conversation) { create(:conversation) }

      it 'returns not found' do
        post api_v1_account_conversation_catalog_message_url(account_id: account.id, conversation_id: other_conversation.display_id),
             params: params, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when retrying a failed catalog message' do
      let(:message) do
        create(:message, conversation: conversation, account: account, message_type: :outgoing, status: :failed,
                         content_attributes: { external_error: 'error', whatsapp_catalog: { kind: 'carousel', catalog_id: 'cat-123' } })
      end

      it 'keeps the whatsapp catalog' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{message.id}/retry",
             headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        expect(message.reload.content_attributes['whatsapp_catalog']).to include('kind' => 'carousel', 'catalog_id' => 'cat-123')
      end
    end
  end
end
