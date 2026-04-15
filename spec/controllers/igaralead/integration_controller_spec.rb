# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Igaralead::IntegrationController, type: :request do
  let(:api_key) { 'test-hub-api-key' }
  let!(:account) { create(:account, hub_client_slug: 'test-slug') }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('HUB_API_KEY', '').and_return(api_key)
  end

  describe 'API Key Authentication' do
    it 'rejects requests without API key' do
      post '/igaralead/api/conversations/find_or_create',
           params: { client_slug: 'test-slug' }.to_json,
           headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects requests with wrong API key' do
      post '/igaralead/api/conversations/find_or_create',
           params: { client_slug: 'test-slug' }.to_json,
           headers: {
             'Content-Type' => 'application/json',
             'X-Api-Key' => 'wrong-key'
           }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects requests with empty API key' do
      post '/igaralead/api/conversations/find_or_create',
           params: { client_slug: 'test-slug' }.to_json,
           headers: {
             'Content-Type' => 'application/json',
             'X-Api-Key' => ''
           }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'accepts requests with valid API key' do
      post '/igaralead/api/conversations/find_or_create',
           params: {
             client_slug: 'test-slug',
             phone: '+5511999990000',
             name: 'Test Contact'
           }.to_json,
           headers: {
             'Content-Type' => 'application/json',
             'X-Api-Key' => api_key
           }
      # Should pass auth (may fail on missing inbox, that's OK)
      expect(response).not_to have_http_status(:unauthorized)
    end
  end

  describe 'POST /igaralead/api/conversations/find_or_create' do
    let(:headers) do
      {
        'Content-Type' => 'application/json',
        'X-Api-Key' => api_key
      }
    end

    it 'rejects request with invalid client_slug' do
      post '/igaralead/api/conversations/find_or_create',
           params: { client_slug: 'nonexistent-slug', phone: '+5511999990000' }.to_json,
           headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it 'rejects request without required phone/email' do
      post '/igaralead/api/conversations/find_or_create',
           params: { client_slug: 'test-slug' }.to_json,
           headers: headers
      expect(response.status).to be_in([400, 422])
    end
  end

  describe 'POST /igaralead/api/messages' do
    let(:headers) do
      {
        'Content-Type' => 'application/json',
        'X-Api-Key' => api_key
      }
    end

    it 'rejects message to nonexistent conversation' do
      post '/igaralead/api/messages',
           params: {
             client_slug: 'test-slug',
             conversation_id: 999_999,
             content: 'Hello'
           }.to_json,
           headers: headers
      expect(response.status).to be_in([404, 422])
    end
  end

  describe 'POST /igaralead/api/contacts/import' do
    let(:headers) do
      {
        'Content-Type' => 'application/json',
        'X-Api-Key' => api_key
      }
    end

    it 'rejects import with invalid client_slug' do
      post '/igaralead/api/contacts/import',
           params: { client_slug: 'nonexistent', contacts: [] }.to_json,
           headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it 'handles empty contacts array gracefully' do
      post '/igaralead/api/contacts/import',
           params: { client_slug: 'test-slug', contacts: [] }.to_json,
           headers: headers
      expect(response).not_to have_http_status(:internal_server_error)
    end
  end
end
