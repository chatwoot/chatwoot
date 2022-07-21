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
        expect(body[:payload].first[:id]).to eq(automation_rule.id)
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
          'name': 'Notify Conversation Created and mark priority query',
          'description': 'Notify all administrator about conversation created and mark priority query',
          'event_name': 'conversation_created',
          'conditions': [
            {
              'attribute_key': 'browser_language',
              'filter_operator': 'equal_to',
              'values': ['en'],
              'query_operator': 'AND'
            },
            {
              'attribute_key': 'country_code',
              'filter_operator': 'equal_to',
              'values': %w[USA UK],
              'query_operator': nil
            }
          ],
          'actions': [
            {
              'action_name': :send_message,
              'action_params': ['Welcome to the chatwoot platform.']
            },
            {
              'action_name': :assign_team,
              'action_params': [1]
            },
            {
              'action_name': :add_label,
              'action_params': %w[support priority_customer]
            },
            {
              'action_name': :assign_best_administrator,
              'action_params': [1]
            },
            {
              'action_name': :update_additional_attributes,
              'action_params': [{ intiated_at: '2021-12-03 17:25:26.844536 +0530' }]
            }
          ]
        }
      end

      it 'throws an error for unknown attributes in condtions' do
        expect(account.automation_rules.count).to eq(0)
        params[:conditions] << {
          'attribute_key': 'unknown_attribute',
          'filter_operator': 'equal_to',
          'values': ['en'],
          'query_operator': 'AND'
        }

        post "/api/v1/accounts/#{account.id}/automation_rules",
             headers: administrator.create_new_auth_token,
             params: params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(account.automation_rules.count).to eq(0)
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
          }
        ]
        expect(account.automation_rules.count).to eq(0)

        post "/api/v1/accounts/#{account.id}/automation_rules",
             headers: administrator.create_new_auth_token,
             params: params

        expect(response).to have_http_status(:success)
        expect(account.automation_rules.count).to eq(1)
      end

      it 'Saves file in the automation actions to send an attachments' do
        file = fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png')

        expect(account.automation_rules.count).to eq(0)

        post "/api/v1/accounts/#{account.id}/automation_rules/attach_file",
             headers: administrator.create_new_auth_token,
             params: { attachment: file }

        expect(response).to have_http_status(:success)

        blob = JSON.parse(response.body)

        expect(blob['blob_key']).to be_present
        expect(blob['blob_id']).to be_present

        params[:actions] = [
          {
            'action_name': :send_message,
            'action_params': ['Welcome to the chatwoot platform.']
          },
          {
            'action_name': :send_attachment,
            'action_params': [blob['blob_id']]
          }
        ]

        post "/api/v1/accounts/#{account.id}/automation_rules",
             headers: administrator.create_new_auth_token,
             params: params

        automation_rule = account.automation_rules.first
        expect(automation_rule.files.presence).to be_truthy
        expect(automation_rule.files.count).to eq(1)
      end

      it 'Saves files in the automation actions to send multiple attachments' do
        file_1 = fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png')
        file_2 = fixture_file_upload(Rails.root.join('spec/assets/sample.png'), 'image/png')

        post "/api/v1/accounts/#{account.id}/automation_rules/attach_file",
             headers: administrator.create_new_auth_token,
             params: { attachment: file_1 }

        blob_1 = JSON.parse(response.body)

        post "/api/v1/accounts/#{account.id}/automation_rules/attach_file",
             headers: administrator.create_new_auth_token,
             params: { attachment: file_2 }

        blob_2 = JSON.parse(response.body)

        params[:actions] = [
          {
            'action_name': :send_attachment,
            'action_params': [blob_1['blob_id']]
          },
          {
            'action_name': :send_attachment,
            'action_params': [blob_2['blob_id']]
          }
        ]

        post "/api/v1/accounts/#{account.id}/automation_rules",
             headers: administrator.create_new_auth_token,
             params: params

        automation_rule = account.automation_rules.first
        expect(automation_rule.files.count).to eq(2)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/automation_rules/{automation_rule.id}' do
    let!(:automation_rule) { create(:automation_rule, account: account, name: 'Test Automation Rule') }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/automation_rules/#{automation_rule.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns for automation_rule for account' do
        expect(account.automation_rules.count).to eq(1)

        get "/api/v1/accounts/#{account.id}/automation_rules/#{automation_rule.id}",
            headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body, symbolize_names: true)
        expect(body[:payload]).to be_present
        expect(body[:payload][:id]).to eq(automation_rule.id)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/automation_rules/{automation_rule.id}/clone' do
    let!(:automation_rule) { create(:automation_rule, account: account, name: 'Test Automation Rule') }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/automation_rules/#{automation_rule.id}/clone"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns for cloned automation_rule for account' do
        expect(account.automation_rules.count).to eq(1)

        post "/api/v1/accounts/#{account.id}/automation_rules/#{automation_rule.id}/clone",
             headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body, symbolize_names: true)
        expect(body[:payload]).to be_present
        expect(body[:payload][:id]).not_to eq(automation_rule.id)
        expect(account.automation_rules.count).to eq(2)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/automation_rules/{automation_rule.id}' do
    let!(:automation_rule) { create(:automation_rule, account: account, name: 'Test Automation Rule') }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/automation_rules/#{automation_rule.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:update_params) do
        {
          'description': 'Update description',
          'name': 'Update name',
          'conditions': [
            {
              'attribute_key': 'browser_language',
              'filter_operator': 'equal_to',
              'values': ['en'],
              'query_operator': 'AND'
            }
          ],
          'actions': [
            {
              'action_name': :update_additional_attributes,
              'action_params': [{ intiated_at: '2021-12-03 17:25:26.844536 +0530' }]
            }
          ]
        }
      end

      it 'returns for cloned automation_rule for account' do
        expect(account.automation_rules.count).to eq(1)
        expect(account.automation_rules.first.actions.size).to eq(4)

        patch "/api/v1/accounts/#{account.id}/automation_rules/#{automation_rule.id}",
              headers: administrator.create_new_auth_token,
              params: update_params

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body, symbolize_names: true)
        expect(body[:payload][:name]).to eq('Update name')
        expect(body[:payload][:description]).to eq('Update description')
        expect(body[:payload][:conditions].size).to eq(1)
        expect(body[:payload][:actions].size).to eq(1)
      end

      it 'returns for updated active flag for automation_rule' do
        expect(automation_rule.active).to be(true)
        params = { active: false }

        patch "/api/v1/accounts/#{account.id}/automation_rules/#{automation_rule.id}",
              headers: administrator.create_new_auth_token,
              params: params

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body, symbolize_names: true)
        expect(body[:payload][:active]).to be(false)
        expect(automation_rule.reload.active).to be(false)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/automation_rules/{automation_rule.id}' do
    let!(:automation_rule) { create(:automation_rule, account: account, name: 'Test Automation Rule') }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/automation_rules/#{automation_rule.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'delete the automation_rule for account' do
        expect(account.automation_rules.count).to eq(1)

        delete "/api/v1/accounts/#{account.id}/automation_rules/#{automation_rule.id}",
               headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)
        expect(account.automation_rules.count).to eq(0)
      end
    end
  end
end
