require 'rails_helper'

RSpec.describe 'Api::V1::Summaries', type: :request do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }

  before do
    allow(GlobalConfig).to receive(:get_value).with('CONVERSATION_SUMMARY_API_URL').and_return('http://example.com/summary')
  end

  describe 'GET /api/v1/summaries' do
    context 'when unauthenticated' do
      it 'returns unauthorized' do
        get "/api/v1/summaries?conversation_id=#{conversation.display_id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'returns summary successfully' do
        response_double = double(success?: true, body: { body: { data: { summary: 'New summary' } } }.to_json)
        allow(HTTParty).to receive(:post).and_return(response_double)

        get '/api/v1/summaries',
            params: { conversation_id: conversation.display_id },
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['summary']).to eq('New summary')
        expect(conversation.reload.summary).to eq('New summary')
      end

      it 'returns cached summary if available' do
        conversation.update!(summary: 'Cached summary', summary_updated_at: Time.current)

        get '/api/v1/summaries',
            params: { conversation_id: conversation.display_id },
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['summary']).to eq('Cached summary')
        expect(json['cached']).to be true
      end

      it 'respects rate limit on force refresh' do
        conversation.update!(
          summary: 'Old summary',
          summary_updated_at: 1.hour.ago,
          conversation_summary_last_generated_at: 1.hour.ago
        )

        get '/api/v1/summaries',
            params: { conversation_id: conversation.display_id, force_refresh: true },
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['cached']).to be true
        expect(json['alert_message']).to be_present
      end
    end
  end
end
