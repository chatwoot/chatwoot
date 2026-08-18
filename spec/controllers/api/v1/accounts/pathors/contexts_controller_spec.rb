require 'rails_helper'

RSpec.describe 'Pathors Context API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:agent_bot) { create(:agent_bot, account: account) }
  let(:contact) { create(:contact, account: account, name: 'Wei Chen', phone_number: '+886912345678') }
  let(:conversation) { create(:conversation, account: account, contact: contact) }
  let(:ticket) { create(:ticket, account: account, conversation: conversation, subject: 'Broken water heater') }

  describe 'GET /api/v1/accounts/{account.id}/pathors/context' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/pathors/context", params: { phone: contact.phone_number }, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns the context' do
        get "/api/v1/accounts/#{account.id}/pathors/context",
            params: { phone: contact.phone_number }, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['contact']['id']).to eq(contact.id)
      end
    end

    context 'when it is an agent bot' do
      it 'returns the context' do
        get "/api/v1/accounts/#{account.id}/pathors/context",
            params: { phone: contact.phone_number }, headers: { api_access_token: agent_bot.access_token.token }, as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['contact']['id']).to eq(contact.id)
      end
    end

    context 'when it is an administrator' do
      it 'finds the contact by phone number' do
        ticket

        get "/api/v1/accounts/#{account.id}/pathors/context",
            params: { phone: contact.phone_number }, headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body['contact']['phone_number']).to eq('+886912345678')
        expect(body['open_tickets'].pluck('id')).to eq([ticket.id])
        expect(body['recent_conversations'].pluck('id')).to eq([conversation.display_id])
      end

      it 'finds the contact by contact_id' do
        get "/api/v1/accounts/#{account.id}/pathors/context",
            params: { contact_id: contact.id }, headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['contact']['id']).to eq(contact.id)
      end

      it 'returns bad request when neither phone nor contact_id is given' do
        get "/api/v1/accounts/#{account.id}/pathors/context", headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:bad_request)
      end

      it 'returns contact_not_found for an unknown phone number' do
        get "/api/v1/accounts/#{account.id}/pathors/context",
            params: { phone: '+886900000000' }, headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body['error']).to eq('contact_not_found')
      end

      it 'returns contact_not_found for a contact outside the account' do
        other_contact = create(:contact)

        get "/api/v1/accounts/#{account.id}/pathors/context",
            params: { contact_id: other_contact.id }, headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'excludes tickets on resolved conversations' do
        resolved_conversation = create(:conversation, account: account, contact: contact, status: :resolved)
        resolved_ticket = create(:ticket, account: account, conversation: resolved_conversation, subject: 'Already handled')

        get "/api/v1/accounts/#{account.id}/pathors/context",
            params: { phone: contact.phone_number }, headers: admin.create_new_auth_token, as: :json

        expect(response.parsed_body['open_tickets'].pluck('id')).not_to include(resolved_ticket.id)
      end

      it 'excludes tickets belonging to another contact' do
        other_ticket = create(:ticket, account: account, conversation: create(:conversation, account: account))

        get "/api/v1/accounts/#{account.id}/pathors/context",
            params: { phone: contact.phone_number }, headers: admin.create_new_auth_token, as: :json

        expect(response.parsed_body['open_tickets'].pluck('id')).not_to include(other_ticket.id)
      end

      it 'sorts open tickets by due date with undated ones last' do
        undated = create(:ticket, account: account, conversation: create(:conversation, account: account, contact: contact), due_at: nil)
        later = create(:ticket, account: account, conversation: create(:conversation, account: account, contact: contact),
                                due_at: 3.days.from_now)
        sooner = create(:ticket, account: account, conversation: create(:conversation, account: account, contact: contact),
                                 due_at: 1.day.from_now)

        get "/api/v1/accounts/#{account.id}/pathors/context",
            params: { phone: contact.phone_number }, headers: admin.create_new_auth_token, as: :json

        expect(response.parsed_body['open_tickets'].pluck('id')).to eq([sooner.id, later.id, undated.id])
      end

      it 'caps open tickets at 20' do
        create_list(:conversation, 21, account: account, contact: contact).each do |conv|
          create(:ticket, account: account, conversation: conv)
        end

        get "/api/v1/accounts/#{account.id}/pathors/context",
            params: { phone: contact.phone_number }, headers: admin.create_new_auth_token, as: :json

        expect(response.parsed_body['open_tickets'].size).to eq(20)
      end

      it 'returns only the three most recent conversations' do
        create_list(:conversation, 4, account: account, contact: contact)

        get "/api/v1/accounts/#{account.id}/pathors/context",
            params: { phone: contact.phone_number }, headers: admin.create_new_auth_token, as: :json

        expect(response.parsed_body['recent_conversations'].size).to eq(3)
      end

      it 'includes the contact and the open tickets in the llm context' do
        ticket

        get "/api/v1/accounts/#{account.id}/pathors/context",
            params: { phone: contact.phone_number }, headers: admin.create_new_auth_token, as: :json

        llm_context = response.parsed_body['llm_context']
        expect(llm_context).to include('Wei Chen')
        expect(llm_context).to include('+886912345678')
        expect(llm_context).to include('Broken water heater')
        expect(llm_context).to include("##{conversation.display_id}")
      end

      it 'states that there are no open tickets when the contact has none' do
        get "/api/v1/accounts/#{account.id}/pathors/context",
            params: { phone: contact.phone_number }, headers: admin.create_new_auth_token, as: :json

        expect(response.parsed_body['llm_context']).to include('No open tickets for this contact')
      end
    end
  end
end
