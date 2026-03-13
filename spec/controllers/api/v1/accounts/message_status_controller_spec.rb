require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::MessageStatusController', type: :request do
  let(:account) { create(:account) }
  let(:other_account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  describe 'POST /api/v1/accounts/{account.id}/message_status' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/message_status",
             params: { ids: [1, 2, 3] },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, inbox: inbox, user: agent)
      end

      context 'with valid message IDs' do
        let!(:message1) { create(:message, account: account, conversation: conversation, status: :sent) }
        let!(:message2) { create(:message, account: account, conversation: conversation, status: :delivered) }
        let!(:message3) { create(:message, account: account, conversation: conversation, status: :read) }

        it 'returns message statuses for valid IDs' do
          post "/api/v1/accounts/#{account.id}/message_status",
               params: { ids: [message1.id, message2.id, message3.id] },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:success)
          json_response = response.parsed_body
          expect(json_response['messages']).to be_an(Array)
          expect(json_response['messages'].length).to eq(3)

          message_statuses = json_response['messages'].map { |m| [m['ID'], m['Status']] }.to_h
          expect(message_statuses[message1.id]).to eq('sent')
          expect(message_statuses[message2.id]).to eq('delivered')
          expect(message_statuses[message3.id]).to eq('read')
        end

        it 'returns only messages from the current account' do
          other_inbox = create(:inbox, account: other_account)
          other_conversation = create(:conversation, account: other_account, inbox: other_inbox)
          other_message = create(:message, account: other_account, conversation: other_conversation)

          post "/api/v1/accounts/#{account.id}/message_status",
               params: { ids: [message1.id, other_message.id] },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:success)
          json_response = response.parsed_body
          expect(json_response['messages'].length).to eq(1)
          expect(json_response['messages'].first['ID']).to eq(message1.id)
        end

        it 'returns only messages from inboxes the agent has access to' do
          other_inbox = create(:inbox, account: account)
          other_conversation = create(:conversation, account: account, inbox: other_inbox)
          other_message = create(:message, account: account, conversation: other_conversation)

          post "/api/v1/accounts/#{account.id}/message_status",
               params: { ids: [message1.id, other_message.id] },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:success)
          json_response = response.parsed_body
          expect(json_response['messages'].length).to eq(1)
          expect(json_response['messages'].first['ID']).to eq(message1.id)
          expect(json_response['messages'].first['ID']).not_to eq(other_message.id)
        end

        it 'returns empty array when no matching messages found' do
          post "/api/v1/accounts/#{account.id}/message_status",
               params: { ids: [99_999, 99_998] },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:success)
          json_response = response.parsed_body
          expect(json_response['messages']).to eq([])
        end

        it 'handles partial matches correctly' do
          post "/api/v1/accounts/#{account.id}/message_status",
               params: { ids: [message1.id, 99_999, message2.id] },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:success)
          json_response = response.parsed_body
          expect(json_response['messages'].length).to eq(2)
          returned_ids = json_response['messages'].map { |m| m['ID'] }
          expect(returned_ids).to contain_exactly(message1.id, message2.id)
        end
      end

      context 'with empty ids array' do
        it 'returns bad request error' do
          post "/api/v1/accounts/#{account.id}/message_status",
               params: { ids: [] },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:bad_request)
          json_response = response.parsed_body
          expect(json_response['error']).to eq('ids parameter is required')
        end
      end

      context 'with missing ids parameter' do
        it 'returns bad request error' do
          post "/api/v1/accounts/#{account.id}/message_status",
               params: {},
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:bad_request)
          json_response = response.parsed_body
          expect(json_response['error']).to eq('ids parameter is required')
        end
      end

      context 'with different message statuses' do
        let!(:sent_message) { create(:message, account: account, conversation: conversation, status: :sent) }
        let!(:delivered_message) { create(:message, account: account, conversation: conversation, status: :delivered) }
        let!(:read_message) { create(:message, account: account, conversation: conversation, status: :read) }
        let!(:failed_message) { create(:message, account: account, conversation: conversation, status: :failed) }

        it 'returns correct status for each message type' do
          post "/api/v1/accounts/#{account.id}/message_status",
               params: { ids: [sent_message.id, delivered_message.id, read_message.id, failed_message.id] },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:success)
          json_response = response.parsed_body
          expect(json_response['messages'].length).to eq(4)

          statuses = json_response['messages'].map { |m| [m['ID'], m['Status']] }.to_h
          expect(statuses[sent_message.id]).to eq('sent')
          expect(statuses[delivered_message.id]).to eq('delivered')
          expect(statuses[read_message.id]).to eq('read')
          expect(statuses[failed_message.id]).to eq('failed')
        end
      end
    end

    context 'when it is an authenticated administrator' do
      let(:administrator) { create(:user, account: account, role: :administrator) }

      let!(:message1) { create(:message, account: account, conversation: conversation, status: :sent) }
      let!(:message2) { create(:message, account: account, conversation: conversation, status: :delivered) }

      it 'returns message statuses successfully' do
        post "/api/v1/accounts/#{account.id}/message_status",
             params: { ids: [message1.id, message2.id] },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['messages'].length).to eq(2)
      end

      it 'can access messages from all inboxes' do
        other_inbox = create(:inbox, account: account)
        other_conversation = create(:conversation, account: account, inbox: other_inbox)
        other_message = create(:message, account: account, conversation: other_conversation)

        post "/api/v1/accounts/#{account.id}/message_status",
             params: { ids: [message1.id, other_message.id] },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['messages'].length).to eq(2)
      end
    end
  end
end

