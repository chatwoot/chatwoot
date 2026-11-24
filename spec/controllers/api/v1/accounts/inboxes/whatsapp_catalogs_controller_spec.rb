require 'rails_helper'

RSpec.describe 'Inbox WhatsApp catalog API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:whatsapp_inbox) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false).inbox
  end

  describe 'GET /api/v1/accounts/{account.id}/inboxes/{id}/whatsapp_catalog' do
    let(:url) { "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/whatsapp_catalog" }
    let(:catalog_result) { { status: 'ok', catalog_id: 'cat_1', collections: [] } }

    it 'returns unauthorized for unauthenticated user' do
      get url

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns the catalog for an agent with inbox access' do
      create(:inbox_member, user: agent, inbox: whatsapp_inbox)
      service = instance_double(Whatsapp::CatalogService, perform: catalog_result)
      allow(Whatsapp::CatalogService).to receive(:new).with(channel: whatsapp_inbox.channel, refresh: nil).and_return(service)

      get url, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response).to conform_schema(200)
      expect(response.parsed_body).to include('status' => 'ok', 'catalog_id' => 'cat_1')
    end

    it 'passes the refresh param to the service' do
      create(:inbox_member, user: agent, inbox: whatsapp_inbox)
      service = instance_double(Whatsapp::CatalogService, perform: catalog_result)
      allow(Whatsapp::CatalogService).to receive(:new).with(channel: whatsapp_inbox.channel, refresh: '1').and_return(service)

      get "#{url}?refresh=1", headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
    end

    it 'returns unauthorized for an agent without inbox access' do
      get url, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns unprocessable entity for a non WhatsApp Cloud inbox' do
      inbox = create(:inbox, account: account)

      get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/whatsapp_catalog", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/inboxes/{id}/whatsapp_catalog_products' do
    let(:url) { "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/whatsapp_catalog_products" }
    let(:service) { instance_double(Whatsapp::CatalogService, products: { status: 'ok', products: [], next_cursor: nil }) }

    before do
      create(:inbox_member, user: agent, inbox: whatsapp_inbox)
      allow(Whatsapp::CatalogService).to receive(:new).with(channel: whatsapp_inbox.channel, refresh: nil).and_return(service)
    end

    it 'returns unauthorized for unauthenticated user' do
      get url

      expect(response).to have_http_status(:unauthorized)
    end

    it 'uses the default limit of 24 and passes the filters' do
      get "#{url}?after=c1&q=%20mug%20&collection_id=set_1", headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response).to conform_schema(200)
      expect(response.parsed_body).to include('status' => 'ok', 'next_cursor' => nil)
      expect(service).to have_received(:products).with(limit: 24, after: 'c1', query: 'mug', collection_id: 'set_1')
    end

    it 'accepts the maximum limit of 50' do
      get "#{url}?limit=50", headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(service).to have_received(:products).with(hash_including(limit: 50))
    end

    it 'rejects a limit above 50 or invalid' do
      %w[51 0 abc].each do |limit|
        get "#{url}?limit=#{limit}", headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    it 'rejects filters that are not strings' do
      get "#{url}?q[]=mug", headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(service).not_to have_received(:products)
    end

    it 'returns 422 for a collection outside the catalog' do
      allow(service).to receive(:products).and_return(status: 'invalid_collection')

      get "#{url}?collection_id=foreign", headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).to conform_schema(422)
      expect(response.parsed_body).to have_key('error')
    end

    it 'returns unauthorized for an agent without inbox access' do
      other = create(:user, account: account, role: :agent)

      get url, headers: other.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns unprocessable entity for a non WhatsApp Cloud inbox' do
      inbox = create(:inbox, account: account)

      get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/whatsapp_catalog_products", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
