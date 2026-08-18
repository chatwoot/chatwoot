require 'rails_helper'

RSpec.describe 'Conversation Tickets API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:conversation) { create(:conversation, account: account) }
  let(:agent_bot) { create(:agent_bot, account: account) }
  let(:url) { "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/ticket" }

  before { create(:inbox_member, user: agent, inbox: conversation.inbox) }

  describe 'GET /api/v1/accounts/{account.id}/conversations/{display_id}/ticket' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get url, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      it 'returns not found when the conversation has no ticket' do
        get url, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'returns the ticket with its tasks' do
        ticket = create(:ticket, account: account, conversation: conversation, subject: 'Refund request')
        create(:ticket_task, account: account, ticket: ticket, title: 'Check the payment gateway')

        get url, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body['id']).to eq(ticket.id)
        expect(body['conversation_id']).to eq(conversation.display_id)
        expect(body['subject']).to eq('Refund request')
        expect(body['status_category']).to eq('triage')
        expect(body['open_tasks_count']).to eq(1)
        expect(body['tasks'].first['title']).to eq('Check the payment gateway')
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/conversations/{display_id}/ticket' do
    let(:payload) { { subject: 'Damaged item', ticket_type: 'complaint', waiting_on: 'customer', waiting_note: 'awaiting photos' } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post url, params: payload, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      it 'creates the ticket' do
        expect do
          post url, params: payload, headers: agent.create_new_auth_token, as: :json
        end.to change(Ticket, :count).by(1)

        expect(response).to have_http_status(:success)
        ticket = conversation.reload.ticket
        expect(ticket.subject).to eq('Damaged item')
        expect(ticket.ticket_type).to eq('complaint')
        expect(ticket.waiting_on).to eq('customer')
        expect(ticket.waiting_note).to eq('awaiting photos')
        expect(ticket.created_by_id).to eq(agent.id)
      end

      it 'returns the existing ticket instead of creating a second one' do
        existing = create(:ticket, account: account, conversation: conversation)

        expect do
          post url, params: payload, headers: agent.create_new_auth_token, as: :json
        end.not_to change(Ticket, :count)

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['id']).to eq(existing.id)
      end

      it 'rejects a ticket without a subject' do
        post url, params: payload.except(:subject), headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns not found for a conversation outside the account' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id + 9999}/ticket",
             params: payload, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when it is an agent bot' do
      it 'creates the ticket without a creator' do
        post url, params: payload, headers: { api_access_token: agent_bot.access_token.token }, as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.ticket.created_by_id).to be_nil
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/conversations/{display_id}/ticket' do
    context 'when it is an authenticated agent' do
      it 'updates the ticket' do
        create(:ticket, account: account, conversation: conversation)

        patch url, params: { waiting_on: 'internal', waiting_note: 'waiting on finance', due_at: '2026-09-01T10:00:00Z' },
                   headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        ticket = conversation.reload.ticket
        expect(ticket.waiting_on).to eq('internal')
        expect(ticket.waiting_note).to eq('waiting on finance')
        expect(ticket.due_at).to eq(Time.zone.parse('2026-09-01T10:00:00Z'))
      end

      it 'returns not found when there is no ticket' do
        patch url, params: { waiting_on: 'internal' }, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when it is an agent bot' do
      it 'updates the ticket' do
        create(:ticket, account: account, conversation: conversation)

        patch url, params: { waiting_on: 'external' }, headers: { api_access_token: agent_bot.access_token.token }, as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.ticket.waiting_on).to eq('external')
      end
    end
  end
end
