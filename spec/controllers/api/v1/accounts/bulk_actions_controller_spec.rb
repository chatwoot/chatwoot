require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::BulkActionsController', type: :request do
  include ActiveJob::TestHelper
  let(:account) { create(:account) }
  let(:agent_1) { create(:user, account: account, role: :agent) }
  let(:agent_2) { create(:user, account: account, role: :agent) }

  before do
    Rails.application.config.active_job.queue_adapter = :inline

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
             params: { status: 'open', conversation_ids: [1, 2, 3] }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'Bulk update conversation status' do
        params = { status: 'snoozed', conversation_ids: Conversation.first(3).pluck(:display_id) }

        expect(Conversation.first.status).to eq('open')
        expect(Conversation.last.status).to eq('open')
        expect(Conversation.first.assignee_id).to eq(nil)

        post "/api/v1/accounts/#{account.id}/bulk_actions",
             headers: agent.create_new_auth_token,
             params: { status: 'snoozed', conversation_ids: %w[1 2 3] }

        expect(response).to have_http_status(:success)

        perform_enqueued_jobs do
          ::BulkActionsJob.new.perform(account: account, params: params, method_type: :update)
        end

        expect(Conversation.first.status).to eq('snoozed')
        expect(Conversation.last.status).to eq('open')
        expect(Conversation.first.assignee_id).to eq(nil)
      end

      it 'Bulk update conversation assignee id' do
        params = { assignee_id: agent_1.id, conversation_ids: Conversation.first(3).pluck(:display_id) }

        expect(Conversation.first.status).to eq('open')
        expect(Conversation.first.assignee_id).to eq(nil)
        expect(Conversation.second.assignee_id).to eq(nil)

        post "/api/v1/accounts/#{account.id}/bulk_actions",
             headers: agent.create_new_auth_token,
             params: { assignee_id: agent_1.id, conversation_ids: %w[1 2 3] }

        expect(response).to have_http_status(:success)

        perform_enqueued_jobs do
          ::BulkActionsJob.new.perform(account: account, params: params, method_type: :update)
        end

        expect(Conversation.first.assignee_id).to eq(agent_1.id)
        expect(Conversation.second.assignee_id).to eq(agent_1.id)
        expect(Conversation.first.status).to eq('open')
      end

      it 'Bulk update conversation status and assignee id' do
        params = { assignee_id: agent_1.id, conversation_ids: Conversation.first(3).pluck(:display_id), status: 'snoozed' }

        expect(Conversation.first.status).to eq('open')
        expect(Conversation.second.assignee_id).to eq(nil)

        post "/api/v1/accounts/#{account.id}/bulk_actions",
             headers: agent.create_new_auth_token,
             params: { assignee_id: agent_1.id, conversation_ids: %w[1 2 3], status: 'snoozed' }

        expect(response).to have_http_status(:success)

        perform_enqueued_jobs do
          ::BulkActionsJob.new.perform(account: account, params: params, method_type: :update)
        end

        expect(Conversation.first.assignee_id).to eq(agent_1.id)
        expect(Conversation.second.assignee_id).to eq(agent_1.id)
        expect(Conversation.first.status).to eq('snoozed')
        expect(Conversation.second.status).to eq('snoozed')
      end

      it 'Bulk update conversation labels' do
        params = { conversation_ids: Conversation.first(3).pluck(:display_id), labels: %w[support priority_customer] }

        expect(Conversation.first.labels).to eq([])
        expect(Conversation.second.labels).to eq([])

        post "/api/v1/accounts/#{account.id}/bulk_actions",
             headers: agent.create_new_auth_token,
             params: { conversation_ids: %w[1 2 3], labels: %w[support priority_customer] }

        expect(response).to have_http_status(:success)

        perform_enqueued_jobs do
          ::BulkActionsJob.new.perform(account: account, params: params, method_type: :update)
        end

        expect(Conversation.first.label_list).to eq(%w[support priority_customer])
        expect(Conversation.second.label_list).to eq(%w[support priority_customer])
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/bulk_actions' do
    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'Bulk delete conversation labels' do
        Conversation.first.add_labels(%w[support priority_customer])
        Conversation.second.add_labels(%w[support priority_customer])
        Conversation.third.add_labels(%w[support priority_customer])

        params = { conversation_ids: Conversation.first(3).pluck(:display_id), labels: %w[support] }

        expect(Conversation.first.label_list).to eq(%w[support priority_customer])
        expect(Conversation.second.label_list).to eq(%w[support priority_customer])

        delete "/api/v1/accounts/#{account.id}/bulk_actions",
               headers: agent.create_new_auth_token,
               params: { conversation_ids: %w[1 2 3], labels: %w[support] }

        expect(response).to have_http_status(:success)

        perform_enqueued_jobs do
          ::BulkActionsJob.new.perform(account: account, params: params, method_type: :delete)
        end

        expect(Conversation.first.label_list).to eq(['priority_customer'])
        expect(Conversation.second.label_list).to eq(['priority_customer'])
      end
    end
  end
end
