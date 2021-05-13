require 'rails_helper'

RSpec.describe '/api/v1/widget/campaigns', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account) }
  let!(:campaign_1) { create(:campaign, inbox: web_widget.inbox, enabled: true, account: account) }
  let!(:campaign_2) { create(:campaign, inbox: web_widget.inbox, enabled: false, account: account) }

  describe 'GET /api/v1/widget/campaigns' do
    let(:params) { { website_token: web_widget.website_token } }

    context 'with correct website token' do
      it 'returns the list of enabled campaigns' do
        get '/api/v1/widget/campaigns', params: params

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq 1
        expect(json_response.pluck('id')).to include(campaign_1.display_id)
        expect(json_response.pluck('id')).not_to include(campaign_2.display_id)
      end
    end

    context 'with invalid website token' do
      it 'returns the list of agents' do
        get '/api/v1/widget/campaigns', params: { website_token: '' }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
