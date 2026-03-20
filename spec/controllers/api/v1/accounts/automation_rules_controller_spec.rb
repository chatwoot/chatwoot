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
            }
          ]
        }
      end

      it 'processes invalid query operator' do
        expect(account.automation_rules.count).to eq(0)
        params[:conditions] << {
          'attribute_key': 'browser_language',
          'filter_operator': 'equal_to',
          'values': ['en'],
          'query_operator': 'invalid'
        }

        post "/api/v1/accounts/#{account.id}/automation_rules",
             headers: administrator.create_new_auth_token,
             params: params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(account.automation_rules.count).to eq(0)
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
        blob = ActiveStorage::Blob.create_and_upload!(
          io: Rails.root.join('spec/assets/avatar.png').open,
          filename: 'avatar.png',
          content_type: 'image/png'
        )

        expect(account.automation_rules.count).to eq(0)

        params[:actions] = [
          {
            'action_name': :send_message,
            'action_params': ['Welcome to the chatwoot platform.']
          },
          {
            'action_name': :send_attachment,
            'action_params': [blob.signed_id]
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
        blob_1 = ActiveStorage::Blob.create_and_upload!(
          io: Rails.root.join('spec/assets/avatar.png').open,
          filename: 'avatar.png',
          content_type: 'image/png'
        )
        blob_2 = ActiveStorage::Blob.create_and_upload!(
          io: Rails.root.join('spec/assets/sample.png').open,
          filename: 'sample.png',
          content_type: 'image/png'
        )

        params[:actions] = [
          {
            'action_name': :send_attachment,
            'action_params': [blob_1.signed_id]
          },
          {
            'action_name': :send_attachment,
            'action_params': [blob_2.signed_id]
          }
        ]

        post "/api/v1/accounts/#{account.id}/automation_rules",
             headers: administrator.create_new_auth_token,
             params: params

        automation_rule = account.automation_rules.first
        expect(automation_rule.files.count).to eq(2)
      end

      it 'returns error for invalid attachment blob_id' do
        params[:actions] = [
          {
            'action_name': :send_attachment,
            'action_params': ['invalid_blob_id']
          }
        ]

        post "/api/v1/accounts/#{account.id}/automation_rules",
             headers: administrator.create_new_auth_token,
             params: params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq(I18n.t('errors.attachments.invalid'))
      end

      it 'stores the original blob_id in action_params after create' do
        blob = ActiveStorage::Blob.create_and_upload!(
          io: Rails.root.join('spec/assets/avatar.png').open,
          filename: 'avatar.png',
          content_type: 'image/png'
        )

        params[:actions] = [
          {
            'action_name': :send_attachment,
            'action_params': [blob.signed_id]
          }
        ]

        post "/api/v1/accounts/#{account.id}/automation_rules",
             headers: administrator.create_new_auth_token,
             params: params

        automation_rule = account.automation_rules.first
        attachment_action = automation_rule.actions.find { |a| a['action_name'] == 'send_attachment' }
        expect(attachment_action['action_params'].first).to be_a(Integer)
        expect(attachment_action['action_params'].first).to eq(automation_rule.files.first.blob_id)
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
              'action_name': :add_label,
              'action_params': %w[support priority_customer]
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

      it 'allows update with existing blob_id' do
        blob = ActiveStorage::Blob.create_and_upload!(
          io: Rails.root.join('spec/assets/avatar.png').open,
          filename: 'avatar.png',
          content_type: 'image/png'
        )

        automation_rule.update!(actions: [{ 'action_name' => 'send_attachment', 'action_params' => [blob.id] }])
        automation_rule.files.attach(blob)

        update_params[:actions] = [
          {
            'action_name': :send_attachment,
            'action_params': [blob.id]
          }
        ]

        patch "/api/v1/accounts/#{account.id}/automation_rules/#{automation_rule.id}",
              headers: administrator.create_new_auth_token,
              params: update_params

        expect(response).to have_http_status(:success)
      end

      it 'returns error for invalid blob_id on update' do
        update_params[:actions] = [
          {
            'action_name': :send_attachment,
            'action_params': [999_999]
          }
        ]

        patch "/api/v1/accounts/#{account.id}/automation_rules/#{automation_rule.id}",
              headers: administrator.create_new_auth_token,
              params: update_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq(I18n.t('errors.attachments.invalid'))
      end

      it 'allows adding new attachment on update with signed blob_id' do
        blob = ActiveStorage::Blob.create_and_upload!(
          io: Rails.root.join('spec/assets/avatar.png').open,
          filename: 'avatar.png',
          content_type: 'image/png'
        )

        update_params[:actions] = [
          {
            'action_name': :send_attachment,
            'action_params': [blob.signed_id]
          }
        ]

        patch "/api/v1/accounts/#{account.id}/automation_rules/#{automation_rule.id}",
              headers: administrator.create_new_auth_token,
              params: update_params

        expect(response).to have_http_status(:success)
        expect(automation_rule.reload.files.count).to eq(1)
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

      it 'deletes automation rule even when it has sent scheduled messages' do
        conversation = create(:conversation, account: account, inbox: inbox, contact: contact)
        scheduled_message = create(:scheduled_message,
                                   account: account,
                                   inbox: inbox,
                                   conversation: conversation,
                                   author: automation_rule)
        scheduled_message.update_column(:status, ScheduledMessage.statuses[:sent]) # rubocop:disable Rails/SkipsModelValidations

        delete "/api/v1/accounts/#{account.id}/automation_rules/#{automation_rule.id}",
               headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)
        expect(account.automation_rules.count).to eq(0)
        expect(scheduled_message.reload.author_id).to be_nil
      end
    end
  end
end
