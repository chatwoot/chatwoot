require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Captain::MessageGenerations', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:message) do
    create(:message, account: account, conversation: conversation, message_type: :outgoing, sender: assistant)
  end

  before { create(:inbox_member, user: agent, inbox: inbox) }

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  describe 'GET /api/v1/accounts/:account_id/captain/message_generations/:id' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/captain/message_generations/#{message.id}", as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the message has a generation record' do
      let!(:generation) do
        create(:captain_message_generation, message: message, assistant: assistant,
                                            reasoning: 'Matched the welcome FAQ', model: 'gpt-4o-mini')
      end

      it 'returns the generation metadata' do
        get "/api/v1/accounts/#{account.id}/captain/message_generations/#{message.id}",
            headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        aggregate_failures do
          expect(json_response[:message_id]).to eq(message.id)
          expect(json_response[:reasoning]).to eq('Matched the welcome FAQ')
          expect(json_response[:model]).to eq('gpt-4o-mini')
          expect(json_response[:citations].size).to eq(generation.citations.size)
          expect(json_response[:citations].first[:title]).to eq(generation.citations.first['title'])
        end
      end

      it 'does not allow an agent without access to the conversation' do
        other_agent = create(:user, account: account, role: :agent)

        get "/api/v1/accounts/#{account.id}/captain/message_generations/#{message.id}",
            headers: other_agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the message has no generation record' do
      it 'returns not found' do
        get "/api/v1/accounts/#{account.id}/captain/message_generations/#{message.id}",
            headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when the message does not belong to the account' do
      it 'returns not found' do
        other_message = create(:message)

        get "/api/v1/accounts/#{account.id}/captain/message_generations/#{other_message.id}",
            headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
