require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::AutomationRules', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:inbox) { create(:inbox, account: account, enable_auto_assignment: false) }
  let!(:contact) { create(:contact, account: account) }
  let!(:contact_inbox) { create(:contact_inbox, inbox_id: inbox.id, contact_id: contact.id) }

  describe 'GET /api/v1/accounts/{account.id}/automation_rules' do
    context 'when it is an authenticated user' do
      it 'returns all records' do
        get "/api/v1/accounts/#{account.id}/automation_rules",
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/automation_rules' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/automation_rules"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) do
        {
          name: 'Notify Conversation Created and mark priority query',
          description: 'Notify all agent about conversation created and mark priority query',
          event_name: 'conversation_created',
          conditions: [
            {
              attribute: 'browser_language',
              filter_operator: 'equal_to',
              value: ['en'],
              query_operator: 'AND'
            },
            {
              attribute: 'country',
              filter_operator: 'equal_to',
              value: %w[USA UK],
              query_operator: nil
            }
          ],
          actions: [
            send_message: { message: 'Welcome to the chatwoot platform.' },
            assign_to_team: [1],
            add_label: ['priority_customer'],
            assign_best_agents: [1, 2, 3, 4],
            update_additional_attributes: [
              intiated_at: Time.now.utc
            ]
          ]
        }.with_indifferent_access
      end

      it 'Saves for automation_rules for account' do
        expect(account.automation_rules.count).to eq(0)

        post "/api/v1/accounts/#{account.id}/automation_rules",
             headers: agent.create_new_auth_token,
             params: params

        expect(response).to have_http_status(:success)
        expect(account.automation_rules.count).to eq(1)

        Conversation.new(account: account, inbox: inbox, contact: contact, contact_inbox_id: contact_inbox.id)
      end
    end
  end
end
