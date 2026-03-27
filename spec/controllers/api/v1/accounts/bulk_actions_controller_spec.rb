require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::BulkActionsController', type: :request do
  include ActiveJob::TestHelper
  let(:account) { create(:account) }
  let(:agent_1) { create(:user, account: account, role: :agent) }
  let(:agent_2) { create(:user, account: account, role: :agent) }
  let(:team_1) { create(:team, account: account) }
  let!(:conversations) do
    [
      create(:conversation, account_id: account.id, status: :open, team_id: team_1.id),
      create(:conversation, account_id: account.id, status: :open, team_id: team_1.id),
      create(:conversation, account_id: account.id, status: :open),
      create(:conversation, account_id: account.id, status: :open)
    ]
  end

  before do
    conversations.each do |conversation|
      conversation.inbox.update!(enable_auto_assignment: false)
      create(:inbox_member, inbox: conversation.inbox, user: agent_1)
      create(:inbox_member, inbox: conversation.inbox, user: agent_2)
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/bulk_action' do
    context 'when it is an unauthenticated user' do
      let!(:agent) { create(:user) }

      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/bulk_actions",
             headers: agent.create_new_auth_token,
             params: { type: 'Conversation', fields: { status: 'open' }, ids: [1, 2, 3] }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let!(:agent) { create(:user, account: account, role: :agent) }

      it 'Ignores bulk_actions for wrong type' do
        post "/api/v1/accounts/#{account.id}/bulk_actions",
             headers: agent.create_new_auth_token,
             params: { type: 'Test', fields: { status: 'snoozed' }, ids: %w[1 2 3] }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'Bulk update conversation status' do
        expect(conversations.first.status).to eq('open')
        expect(conversations.last.status).to eq('open')
        expect(conversations.first.assignee_id).to be_nil

        perform_enqueued_jobs do
          post "/api/v1/accounts/#{account.id}/bulk_actions",
               headers: agent.create_new_auth_token,
               params: { type: 'Conversation', fields: { status: 'snoozed' }, ids: conversations.first(3).pluck(:display_id) }

          expect(response).to have_http_status(:success)
        end

        expect(conversations.first.reload.status).to eq('snoozed')
        expect(conversations.last.reload.status).to eq('open')
        expect(conversations.first.assignee_id).to be_nil
      end

      it 'Bulk update conversation team id to none' do
        params = { type: 'Conversation', fields: { team_id: 0 }, ids: conversations.first(1).pluck(:display_id) }
        expect(conversations.first.team).not_to be_nil

        perform_enqueued_jobs do
          post "/api/v1/accounts/#{account.id}/bulk_actions",
               headers: agent.create_new_auth_token,
               params: params

          expect(response).to have_http_status(:success)
        end

        expect(conversations.first.reload.team).to be_nil

        last_activity_message = conversations.first.messages.activity.last

        expect(last_activity_message.content).to eq("Unassigned from #{team_1.name} by #{agent.name}")
      end

      it 'Bulk update conversation team id to team' do
        params = { type: 'Conversation', fields: { team_id: team_1.id }, ids: conversations.last(2).pluck(:display_id) }
        expect(conversations.last.team_id).to be_nil

        perform_enqueued_jobs do
          post "/api/v1/accounts/#{account.id}/bulk_actions",
               headers: agent.create_new_auth_token,
               params: params

          expect(response).to have_http_status(:success)
        end

        expect(conversations.last.reload.team).to eq(team_1)

        last_activity_message = conversations.last.messages.activity.last

        expect(last_activity_message.content).to eq("Assigned to #{team_1.name} by #{agent.name}")
      end

      it 'Bulk update conversation assignee id' do
        params = { type: 'Conversation', fields: { assignee_id: agent_1.id }, ids: conversations.first(3).pluck(:display_id) }

        expect(conversations.first.status).to eq('open')
        expect(conversations.first.assignee_id).to be_nil
        expect(conversations.second.assignee_id).to be_nil

        perform_enqueued_jobs do
          post "/api/v1/accounts/#{account.id}/bulk_actions",
               headers: agent.create_new_auth_token,
               params: params

          expect(response).to have_http_status(:success)
        end

        expect(conversations.first.reload.assignee_id).to eq(agent_1.id)
        expect(conversations.second.reload.assignee_id).to eq(agent_1.id)
        expect(conversations.first.status).to eq('open')
      end

      it 'Bulk remove assignee id from conversations' do
        conversations.first.update(assignee_id: agent_1.id)
        conversations.second.update(assignee_id: agent_2.id)
        params = { type: 'Conversation', fields: { assignee_id: nil }, ids: conversations.first(3).pluck(:display_id) }

        expect(conversations.first.status).to eq('open')
        expect(conversations.first.assignee_id).to eq(agent_1.id)
        expect(conversations.second.assignee_id).to eq(agent_2.id)

        perform_enqueued_jobs do
          post "/api/v1/accounts/#{account.id}/bulk_actions",
               headers: agent.create_new_auth_token,
               params: params

          expect(response).to have_http_status(:success)
        end

        expect(conversations.first.reload.assignee_id).to be_nil
        expect(conversations.second.reload.assignee_id).to be_nil
        expect(conversations.first.status).to eq('open')
      end

      it 'Do not bulk update status to nil' do
        conversations.first.update(assignee_id: agent_1.id)
        conversations.second.update(assignee_id: agent_2.id)
        params = { type: 'Conversation', fields: { status: nil }, ids: conversations.first(3).pluck(:display_id) }

        expect(conversations.first.status).to eq('open')

        perform_enqueued_jobs do
          post "/api/v1/accounts/#{account.id}/bulk_actions",
               headers: agent.create_new_auth_token,
               params: params

          expect(response).to have_http_status(:success)
        end

        expect(conversations.first.reload.status).to eq('open')
      end

      it 'Bulk update conversation status and assignee id' do
        params = { type: 'Conversation', fields: { assignee_id: agent_1.id, status: 'snoozed' }, ids: conversations.first(3).pluck(:display_id) }

        expect(conversations.first.status).to eq('open')
        expect(conversations.second.assignee_id).to be_nil

        perform_enqueued_jobs do
          post "/api/v1/accounts/#{account.id}/bulk_actions",
               headers: agent.create_new_auth_token,
               params: params

          expect(response).to have_http_status(:success)
        end

        expect(conversations.first.reload.assignee_id).to eq(agent_1.id)
        expect(conversations.second.reload.assignee_id).to eq(agent_1.id)
        expect(conversations.first.status).to eq('snoozed')
        expect(conversations.second.status).to eq('snoozed')
      end

      it 'Bulk update conversation labels' do
        params = { type: 'Conversation', ids: conversations.first(3).pluck(:display_id), labels: { add: %w[support priority_customer] } }

        expect(conversations.first.labels).to eq([])
        expect(conversations.second.labels).to eq([])

        perform_enqueued_jobs do
          post "/api/v1/accounts/#{account.id}/bulk_actions",
               headers: agent.create_new_auth_token,
               params: params

          expect(response).to have_http_status(:success)
        end

        expect(conversations.first.reload.label_list).to contain_exactly('support', 'priority_customer')
        expect(conversations.second.reload.label_list).to contain_exactly('support', 'priority_customer')
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/bulk_actions' do
    context 'when it is an authenticated user' do
      let!(:agent) { create(:user, account: account, role: :agent) }

      it 'Bulk delete conversation labels' do
        conversations.first.add_labels(%w[support priority_customer])
        conversations.second.add_labels(%w[support priority_customer])
        conversations.third.add_labels(%w[support priority_customer])

        params = { type: 'Conversation', ids: conversations.first(3).pluck(:display_id), labels: { remove: %w[support] } }

        expect(conversations.first.label_list).to contain_exactly('support', 'priority_customer')
        expect(conversations.second.label_list).to contain_exactly('support', 'priority_customer')

        perform_enqueued_jobs do
          post "/api/v1/accounts/#{account.id}/bulk_actions",
               headers: agent.create_new_auth_token,
               params: params

          expect(response).to have_http_status(:success)
        end

        expect(conversations.first.reload.label_list).to contain_exactly('priority_customer')
        expect(conversations.second.reload.label_list).to contain_exactly('priority_customer')
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/bulk_actions (contacts)' do
    context 'when it is an authenticated user' do
      let!(:agent) { create(:user, account: account, role: :agent) }

      it 'enqueues Contacts::BulkActionJob with permitted params' do
        contact_one = create(:contact, account: account)
        contact_two = create(:contact, account: account)

        expect do
          post "/api/v1/accounts/#{account.id}/bulk_actions",
               headers: agent.create_new_auth_token,
               params: {
                 type: 'Contact',
                 ids: [contact_one.id, contact_two.id],
                 labels: { add: %w[vip support] },
                 extra: 'ignored'
               }
        end.to have_enqueued_job(Contacts::BulkActionJob).with(
          account.id,
          agent.id,
          hash_including(
            'ids' => [contact_one.id.to_s, contact_two.id.to_s],
            'labels' => hash_including('add' => %w[vip support])
          )
        )

        expect(response).to have_http_status(:success)
      end

      it 'returns unauthorized for delete action when user is not admin' do
        contact = create(:contact, account: account)

        post "/api/v1/accounts/#{account.id}/bulk_actions",
             headers: agent.create_new_auth_token,
             params: {
               type: 'Contact',
               ids: [contact.id],
               action_name: 'delete'
             }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
