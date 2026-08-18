require 'rails_helper'

RSpec.describe 'Tickets API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:team) { create(:team, account: account) }
  let(:url) { "/api/v1/accounts/#{account.id}/tickets" }

  let(:triage_ticket) do
    create(:ticket, account: account, conversation: create(:conversation, account: account), ticket_type: 'question')
  end
  let(:in_progress_ticket) do
    create(:ticket, account: account, ticket_type: 'complaint',
                    conversation: create(:conversation, account: account, assignee: agent))
  end
  let(:team_ticket) do
    create(:ticket, account: account, conversation: create(:conversation, account: account, team: team))
  end
  let(:contact) { create(:contact, account: account) }
  let(:contact_ticket) do
    create(:ticket, account: account, conversation: create(:conversation, account: account, contact: contact))
  end
  let(:contact_done_ticket) do
    conversation = create(:conversation, account: account, contact: contact, assignee: agent)
    conversation.update!(status: :resolved)
    create(:ticket, account: account, conversation: conversation)
  end
  let(:waiting_ticket) do
    create(:ticket, account: account, waiting_on: :customer, conversation: create(:conversation, account: account, assignee: agent))
  end
  let(:done_ticket) do
    conversation = create(:conversation, account: account, assignee: agent)
    conversation.update!(status: :resolved)
    create(:ticket, account: account, conversation: conversation)
  end
  let(:closed_ticket) do
    conversation = create(:conversation, account: account, assignee: agent)
    conversation.update!(status: :resolved)
    create(:ticket, account: account, conversation: conversation, closed_at: Time.current)
  end

  describe 'GET /api/v1/accounts/{account.id}/tickets' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get url, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      it 'lists the tickets of the account' do
        triage_ticket
        in_progress_ticket
        create(:ticket)

        get url, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body['meta']['count']).to eq(2)
        expect(body['payload'].pluck('id')).to contain_exactly(triage_ticket.id, in_progress_ticket.id)
      end

      it 'includes the tasks of each ticket' do
        create(:ticket_task, account: account, ticket: triage_ticket, title: 'Check stock')

        get url, headers: agent.create_new_auth_token, as: :json

        expect(response.parsed_body['payload'].first['tasks'].first['title']).to eq('Check stock')
      end

      it 'filters by status_category' do
        triage_ticket
        in_progress_ticket
        waiting_ticket
        done_ticket
        closed_ticket

        {
          'triage' => triage_ticket, 'in_progress' => in_progress_ticket, 'waiting' => waiting_ticket,
          'done' => done_ticket, 'closed' => closed_ticket
        }.each do |category, ticket|
          get url, params: { status_category: category }, headers: agent.create_new_auth_token, as: :json

          expect(response.parsed_body['payload'].pluck('id')).to eq([ticket.id]), "expected only #{ticket.id} for #{category}"
        end
      end

      it 'returns nothing for an unknown status_category' do
        triage_ticket

        get url, params: { status_category: 'nonsense' }, headers: agent.create_new_auth_token, as: :json

        expect(response.parsed_body['payload']).to be_empty
      end

      it 'returns every unsettled ticket when settled is false' do
        triage_ticket
        in_progress_ticket
        waiting_ticket
        done_ticket
        closed_ticket

        get url, params: { settled: 'false' }, headers: agent.create_new_auth_token, as: :json

        expect(response.parsed_body['payload'].pluck('id')).to contain_exactly(triage_ticket.id, in_progress_ticket.id, waiting_ticket.id)
      end

      it 'keeps the settled tickets when settled is not given' do
        in_progress_ticket
        done_ticket

        get url, headers: agent.create_new_auth_token, as: :json

        expect(response.parsed_body['payload'].pluck('id')).to contain_exactly(in_progress_ticket.id, done_ticket.id)
      end

      it 'filters by waiting_on' do
        triage_ticket
        waiting_ticket

        get url, params: { waiting_on: 'customer' }, headers: agent.create_new_auth_token, as: :json

        expect(response.parsed_body['payload'].pluck('id')).to eq([waiting_ticket.id])
      end

      it 'filters by ticket_type' do
        triage_ticket
        in_progress_ticket

        get url, params: { ticket_type: 'complaint' }, headers: agent.create_new_auth_token, as: :json

        expect(response.parsed_body['payload'].pluck('id')).to eq([in_progress_ticket.id])
      end

      it 'filters by the conversation assignee' do
        triage_ticket
        in_progress_ticket

        get url, params: { assignee_id: agent.id }, headers: agent.create_new_auth_token, as: :json

        expect(response.parsed_body['payload'].pluck('id')).to eq([in_progress_ticket.id])
      end

      it 'filters by the conversation team' do
        triage_ticket
        team_ticket

        get url, params: { team_id: team.id }, headers: agent.create_new_auth_token, as: :json

        expect(response.parsed_body['payload'].pluck('id')).to eq([team_ticket.id])
      end

      it 'filters by the conversation contact' do
        triage_ticket
        contact_ticket

        get url, params: { contact_id: contact.id }, headers: agent.create_new_auth_token, as: :json

        expect(response.parsed_body['payload'].pluck('id')).to eq([contact_ticket.id])
      end

      it 'narrows a contact down to a single status_category' do
        contact_ticket
        contact_done_ticket

        get url, params: { contact_id: contact.id, status_category: 'triage' }, headers: agent.create_new_auth_token, as: :json

        expect(response.parsed_body['payload'].pluck('id')).to eq([contact_ticket.id])
      end

      it 'returns nothing for a contact without tickets' do
        triage_ticket

        get url, params: { contact_id: create(:contact, account: account).id }, headers: agent.create_new_auth_token, as: :json

        expect(response.parsed_body['meta']['count']).to eq(0)
        expect(response.parsed_body['payload']).to be_empty
      end

      it 'filters the overdue tickets' do
        triage_ticket.update!(due_at: 1.day.ago)
        in_progress_ticket.update!(due_at: 1.day.from_now)
        done_ticket.update!(due_at: 1.day.ago)

        get url, params: { overdue: true }, headers: agent.create_new_auth_token, as: :json

        expect(response.parsed_body['payload'].pluck('id')).to eq([triage_ticket.id])
      end

      it 'paginates the results' do
        stub_const('Api::V1::Accounts::TicketsController::RESULTS_PER_PAGE', 1)
        triage_ticket
        in_progress_ticket

        get url, params: { page: 2 }, headers: agent.create_new_auth_token, as: :json

        expect(response.parsed_body['meta']['count']).to eq(2)
        expect(response.parsed_body['meta']['current_page']).to eq(2)
        expect(response.parsed_body['payload'].size).to eq(1)
      end
    end
  end
end
