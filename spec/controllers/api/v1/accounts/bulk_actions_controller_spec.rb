require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::BulkActionsController', type: :request do
  include ActiveJob::TestHelper
  let(:account) { create(:account) }
  let(:agent_1) { create(:user, account: account, role: :agent) }
  let(:agent_2) { create(:user, account: account, role: :agent) }

  before do
    create(:conversation, account_id: account.id, status: :open)
    create(:conversation, account_id: account.id, status: :open)
    create(:conversation, account_id: account.id, status: :open)
    create(:conversation, account_id: account.id, status: :open)
  end

  describe 'POST /api/v1/accounts/{account.id}/bulk_action' do
    context 'when it is an unauthenticated user' do
      let(:agent) { create(:user) }

      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/bulk_actions",
             headers: agent.create_new_auth_token,
             params: { type: 'Conversation', fields: { status: 'open' }, ids: [1, 2, 3] }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'Ignores bulk_actions for wrong type' do
        post "/api/v1/accounts/#{account.id}/bulk_actions",
             headers: agent.create_new_auth_token,
             params: { type: 'Test', fields: { status: 'snoozed' }, ids: %w[1 2 3] }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'Bulk update conversation status' do
        expect(Conversation.first.status).to eq('open')
        expect(Conversation.last.status).to eq('open')
        expect(Conversation.first.assignee_id).to be_nil

        perform_enqueued_jobs do
          post "/api/v1/accounts/#{account.id}/bulk_actions",
               headers: agent.create_new_auth_token,
               params: { type: 'Conversation', fields: { status: 'snoozed' }, ids: Conversation.first(3).pluck(:display_id) }

          expect(response).to have_http_status(:success)
        end

        expect(Conversation.first.status).to eq('snoozed')
        expect(Conversation.last.status).to eq('open')
        expect(Conversation.first.assignee_id).to be_nil
      end

      it 'Bulk update conversation assignee id' do
        params = { type: 'Conversation', fields: { assignee_id: agent_1.id }, ids: Conversation.first(3).pluck(:display_id) }

        expect(Conversation.first.status).to eq('open')
        expect(Conversation.first.assignee_id).to be_nil
        expect(Conversation.second.assignee_id).to be_nil

        perform_enqueued_jobs do
          post "/api/v1/accounts/#{account.id}/bulk_actions",
               headers: agent.create_new_auth_token,
               params: params

          expect(response).to have_http_status(:success)
        end

        expect(Conversation.first.assignee_id).to eq(agent_1.id)
        expect(Conversation.second.assignee_id).to eq(agent_1.id)
        expect(Conversation.first.status).to eq('open')
      end

      it 'Bulk update conversation status and assignee id' do
        params = { type: 'Conversation', fields: { assignee_id: agent_1.id, status: 'snoozed' }, ids: Conversation.first(3).pluck(:display_id) }

        expect(Conversation.first.status).to eq('open')
        expect(Conversation.second.assignee_id).to be_nil

        perform_enqueued_jobs do
          post "/api/v1/accounts/#{account.id}/bulk_actions",
               headers: agent.create_new_auth_token,
               params: params

          expect(response).to have_http_status(:success)
        end

        expect(Conversation.first.assignee_id).to eq(agent_1.id)
        expect(Conversation.second.assignee_id).to eq(agent_1.id)
        expect(Conversation.first.status).to eq('snoozed')
        expect(Conversation.second.status).to eq('snoozed')
      end

      it 'Bulk update conversation labels' do
        params = { type: 'Conversation', ids: Conversation.first(3).pluck(:display_id), labels: { add: %w[support priority_customer] } }

        expect(Conversation.first.labels).to eq([])
        expect(Conversation.second.labels).to eq([])

        perform_enqueued_jobs do
          post "/api/v1/accounts/#{account.id}/bulk_actions",
               headers: agent.create_new_auth_token,
               params: params

          expect(response).to have_http_status(:success)
        end

        expect(Conversation.first.label_list).to contain_exactly('support', 'priority_customer')
        expect(Conversation.second.label_list).to contain_exactly('support', 'priority_customer')
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/bulk_actions' do
    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'Bulk delete conversation labels' do
        Conversation.first.add_labels(%w[support priority_customer])
        Conversation.second.add_labels(%w[support priority_customer])
        Conversation.third.add_labels(%w[support priority_customer])

        params = { type: 'Conversation', ids: Conversation.first(3).pluck(:display_id), labels: { remove: %w[support] } }

        expect(Conversation.first.label_list).to contain_exactly('support', 'priority_customer')
        expect(Conversation.second.label_list).to contain_exactly('support', 'priority_customer')

        perform_enqueued_jobs do
          post "/api/v1/accounts/#{account.id}/bulk_actions",
               headers: agent.create_new_auth_token,
               params: params

          expect(response).to have_http_status(:success)
        end

        expect(Conversation.first.label_list).to contain_exactly('priority_customer')
        expect(Conversation.second.label_list).to contain_exactly('priority_customer')
      end
    end
  end
end
