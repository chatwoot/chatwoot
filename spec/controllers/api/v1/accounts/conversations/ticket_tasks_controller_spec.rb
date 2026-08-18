require 'rails_helper'

RSpec.describe 'Conversation Ticket Tasks API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:team) { create(:team, account: account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:agent_bot) { create(:agent_bot, account: account) }
  let(:ticket) { create(:ticket, account: account, conversation: conversation) }
  let(:url) { "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/ticket/tasks" }

  before { create(:inbox_member, user: agent, inbox: conversation.inbox) }

  describe 'POST /api/v1/accounts/{account.id}/conversations/{display_id}/ticket/tasks' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post url, params: { title: 'Call the courier' }, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      let(:create_payload) do
        { title: 'Call the courier', description: 'Ask for the pickup slot', assignee_id: agent.id, team_id: team.id }
      end

      it 'creates a task on the ticket' do
        ticket

        expect do
          post url, params: create_payload, headers: agent.create_new_auth_token, as: :json
        end.to change(TicketTask, :count).by(1)

        expect(response).to have_http_status(:success)
      end

      it 'stores the submitted attributes on the task' do
        ticket

        post url, params: create_payload, headers: agent.create_new_auth_token, as: :json

        task = ticket.ticket_tasks.last
        expect(task.title).to eq('Call the courier')
        expect(task.description).to eq('Ask for the pickup slot')
        expect(task.status).to eq('open')
        expect(task.assignee_id).to eq(agent.id)
        expect(task.team_id).to eq(team.id)
      end

      it 'stamps the account and the creator' do
        ticket

        post url, params: create_payload, headers: agent.create_new_auth_token, as: :json

        task = ticket.ticket_tasks.last
        expect(task.account_id).to eq(account.id)
        expect(task.created_by_id).to eq(agent.id)
      end

      it 'creates an unassigned task' do
        ticket

        post url, params: { title: 'Draft the refund note' }, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        expect(ticket.ticket_tasks.last.assignee_id).to be_nil
      end

      it 'rejects a task without a title' do
        ticket

        post url, params: { description: 'no title' }, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns not found when the conversation has no ticket' do
        post url, params: { title: 'Call the courier' }, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when it is an agent bot' do
      it 'creates the task' do
        ticket

        post url, params: { title: 'Verify the address' }, headers: { api_access_token: agent_bot.access_token.token }, as: :json

        expect(response).to have_http_status(:success)
        expect(ticket.ticket_tasks.last.created_by_id).to be_nil
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/conversations/{display_id}/ticket/tasks/{id}' do
    let(:task) { create(:ticket_task, account: account, ticket: ticket) }

    it 'marks the task done and stamps completed_at' do
      patch "#{url}/#{task.id}", params: { status: 'done' }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      task.reload
      expect(task.status).to eq('done')
      expect(task.completed_at).to be_present
      expect(response.parsed_body['status']).to eq('done')
    end

    it 'updates the title, assignee, team and due date' do
      patch "#{url}/#{task.id}",
            params: { title: 'Renamed', assignee_id: agent.id, team_id: team.id, due_at: '2026-09-05T09:00:00Z' },
            headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      task.reload
      expect(task.title).to eq('Renamed')
      expect(task.assignee_id).to eq(agent.id)
      expect(task.team_id).to eq(team.id)
      expect(task.due_at).to eq(Time.zone.parse('2026-09-05T09:00:00Z'))
    end

    it 'returns not found for a task on another ticket' do
      other_task = create(:ticket_task)

      patch "#{url}/#{other_task.id}", params: { status: 'done' }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'lets an agent bot complete a task' do
      patch "#{url}/#{task.id}", params: { status: 'done' }, headers: { api_access_token: agent_bot.access_token.token }, as: :json

      expect(response).to have_http_status(:success)
      expect(task.reload.status).to eq('done')
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/conversations/{display_id}/ticket/tasks/{id}' do
    let(:task) { create(:ticket_task, account: account, ticket: ticket) }

    it 'deletes the task' do
      task

      expect do
        delete "#{url}/#{task.id}", headers: agent.create_new_auth_token, as: :json
      end.to change(TicketTask, :count).by(-1)

      expect(response).to have_http_status(:success)
    end

    it 'is not available to an agent bot' do
      delete "#{url}/#{task.id}", headers: { api_access_token: agent_bot.access_token.token }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
