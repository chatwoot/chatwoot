require 'rails_helper'

RSpec.describe '/api/v1/widget/config', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account) }
  let!(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let(:payload) { { source_id: contact_inbox.source_id, inbox_id: web_widget.inbox.id } }
  let(:token) { ::Widget::TokenService.new(payload: payload).generate_token }

  describe 'POST /api/v1/widget/config' do
    let(:params) { { website_token: web_widget.website_token } }
    let(:response_keys) { %w[chatwoot_website_channel chatwoot_widget_defaults contact auth_token global_config] }

    context 'with invalid website token' do
      it 'returns not found' do
        post '/api/v1/widget/config', params: { website_token: '' }
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with correct website token and missing X-Auth-Token' do
      it 'returns widget config along with a new contact' do
        expect do
          post '/api/v1/widget/config',
               params: params,
               as: :json
        end.to change(Contact, :count).by(1)

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body)
        expect(response_data.keys).to include(*response_keys)
      end
    end

    context 'with correct website token and valid X-Auth-Token' do
      it 'returns widget config along with the same contact' do
        expect do
          post '/api/v1/widget/config',
               params: params,
               headers: { 'X-Auth-Token' => token },
               as: :json
        end.to change(Contact, :count).by(0)

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body)
        expect(response_data.keys).to include(*response_keys)
        expect(response_data['contact']['pubsub_token']).to eq(contact.pubsub_token)
      end
    end

    context 'with correct website token and invalid X-Auth-Token' do
      it 'returns widget config and new contact with error message' do
        expect do
          post '/api/v1/widget/config',
               params: params,
               headers: { 'X-Auth-Token' => 'invalid token' },
               as: :json
        end.to change(Contact, :count).by(1)

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body)
        expect(response_data.keys).to include(*response_keys)
      end
    end
  end
end
