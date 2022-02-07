require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::BulkActions::StatusChangesController', type: :request do
  include ActiveJob::TestHelper
  let(:account) { create(:account) }

  describe 'POST /api/v1/accounts/{account.id}/bulk_actions/status_change' do
    before do
      Rails.application.config.active_job.queue_adapter = :inline

      create(:conversation, account_id: account.id, status: :open)
      create(:conversation, account_id: account.id, status: :open)
      create(:conversation, account_id: account.id, status: :open)
      create(:conversation, account_id: account.id, status: :open)
    end

    context 'when it is an unauthenticated user' do
      let(:agent) { create(:user) }

      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/bulk_actions/status_change",
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

        expect(Conversations::StatusChangeJob).to receive(:perform_later).with(
          account: account, conversation_ids: %w[1 2 3], status: params[:status]
        ).once

        post "/api/v1/accounts/#{account.id}/bulk_actions/status_change",
             headers: agent.create_new_auth_token,
             params: { status: 'snoozed', conversation_ids: %w[1 2 3] }

        expect(response).to have_http_status(:success)

        perform_enqueued_jobs do
          Conversations::StatusChangeJob.new.perform(account: account, conversation_ids: %w[1 2 3], status: params[:status])
        end

        expect(Conversation.first.status).to eq('snoozed')
        expect(Conversation.last.status).to eq('open')
      end
    end
  end
end
