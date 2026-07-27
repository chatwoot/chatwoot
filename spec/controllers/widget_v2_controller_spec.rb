require 'rails_helper'

RSpec.describe '/widget/v2', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account) }

  describe 'GET /widget/v2' do
    it 'renders the v2 widget page and bootstraps a contact' do
      get '/widget/v2', params: { website_token: web_widget.website_token }

      expect(response).to have_http_status(:success)
      expect(response.body).to include('window.chatwootPubsubToken')
      expect(response.body).to include(web_widget.website_token)
      expect(web_widget.inbox.contact_inboxes.count).to eq(1)
    end

    it 'returns not found for an invalid website token' do
      get '/widget/v2', params: { website_token: 'invalid' }

      expect(response).to have_http_status(:not_found)
    end
  end
end
