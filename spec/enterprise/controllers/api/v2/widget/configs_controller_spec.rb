require 'rails_helper'

RSpec.describe '/api/v2/widget/config', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let(:assistant) do
    create(:captain_assistant, account: account, config: { 'welcome_message' => 'Hi, ask me anything' })
  end
  let(:token) do
    Widget::TokenService.new(payload: { source_id: contact_inbox.source_id, inbox_id: web_widget.inbox.id }).generate_token
  end

  describe 'GET /api/v2/widget/config' do
    context 'when a captain assistant is connected to the inbox' do
      before do
        create(:captain_inbox, captain_assistant: assistant, inbox: web_widget.inbox)
      end

      it 'exposes the assistant as ai_agent' do
        get '/api/v2/widget/config',
            headers: { 'X-Auth-Token' => token },
            params: { website_token: web_widget.website_token },
            as: :json

        expect(response).to have_http_status(:success)
        ai_agent = response.parsed_body['ai_agent']
        expect(ai_agent['name']).to eq(assistant.name)
        expect(ai_agent['welcome_message']).to eq('Hi, ask me anything')
      end

      it 'returns no ai_agent when the account has no captain credits' do
        create(:installation_config, name: 'CAPTAIN_CLOUD_PLAN_LIMITS',
                                     value: { startups: { documents: 100, responses: 100 } }.to_json)
        account.update!(custom_attributes: { 'plan_name' => 'startups', 'captain_responses_usage' => 100 })

        get '/api/v2/widget/config',
            headers: { 'X-Auth-Token' => token },
            params: { website_token: web_widget.website_token },
            as: :json

        expect(response.parsed_body['ai_agent']).to be_nil
      end
    end
  end
end
