require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::AutomationRulesController', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let!(:inbox) { create(:inbox, account: account, enable_auto_assignment: false) }
  let!(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, inbox_id: inbox.id, contact_id: contact.id) }

  describe 'GET /api/v1/accounts/{account.id}/automation_rules' do
    context 'when it is an authenticated user' do
      it 'returns all records' do
        automation_rule = create(:automation_rule, account: account, name: 'Test Automation Rule')

        get "/api/v1/accounts/#{account.id}/automation_rules",
            headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body, symbolize_names: true)
        expect(body[:data].first[:id]).to eq(automation_rule.id)
      end
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/automation_rules"

        expect(response).to have_http_status(:unauthorized)
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
          description: 'Notify all administrator about conversation created and mark priority query',
          event_name: 'conversation_created',
          conditions: [
            {
              attribute_key: 'browser_language',
              filter_operator: 'equal_to',
              values: ['en'],
              query_operator: 'AND'
            },
            {
              attribute_key: 'country_code',
              filter_operator: 'equal_to',
              values: %w[USA UK],
              query_operator: nil
            }
          ],
          actions: [
            {
              action_name: :send_message,
              action_params: ['Welcome to the chatwoot platform.']
            },
            {
              action_name: :assign_team,
              action_params: [1]
            },
            {
              action_name: :add_label,
              action_params: %w[support priority_customer]
            },
            {
              action_name: :assign_best_administrator,
              action_params: [1]
            },
            {
              action_name: :update_additional_attributes,
              action_params: [{ intiated_at: '2021-12-03 17:25:26.844536 +0530' }]
            }
          ]
        }.with_indifferent_access
      end

      it 'Saves for automation_rules for account with country_code and browser_language conditions' do
        expect(account.automation_rules.count).to eq(0)

        post "/api/v1/accounts/#{account.id}/automation_rules",
             headers: administrator.create_new_auth_token,
             params: params

        expect(response).to have_http_status(:success)
        expect(account.automation_rules.count).to eq(1)
      end

      it 'Saves for automation_rules for account with status conditions' do
        params[:conditions] = [
          {
            attribute_key: 'status',
            filter_operator: 'equal_to',
            values: ['resolved'],
            query_operator: nil
          }.with_indifferent_access
        ]
        expect(account.automation_rules.count).to eq(0)

        post "/api/v1/accounts/#{account.id}/automation_rules",
             headers: administrator.create_new_auth_token,
             params: params

        expect(response).to have_http_status(:success)
        expect(account.automation_rules.count).to eq(1)
      end
    end
  end
end
