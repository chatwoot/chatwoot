require 'rails_helper'

RSpec.describe 'Messages API', type: :request do
  let(:account) { create(:account) }

  describe 'GET /api/v1/accounts/messages' do
    let(:inbox) { create(:inbox, account: account) }
    let(:contact) { create(:contact, account: account) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
    let!(:messages) { create_list(:message, 10, account: account, inbox: inbox, conversation: conversation) }
    let(:agent) { create(:user, account: account, role: :agent) }

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        get api_v1_account_messages_path(account_id: account.id)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'returns messages' do
        get api_v1_account_messages_path(account_id: account.id),
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['payload'].size).to eq(conversation.messages.count)
      end

      context 'when filtered by inbox' do
        before do
          @other_inbox = create(:inbox, account: account)
          @other_conversation = create(:conversation, account: account, inbox: @other_inbox, contact: contact)
          @other_messages = create_list(:message, 5, account: account, inbox: @other_inbox, conversation: @other_conversation)
        end

        it 'returns correct messages count' do
          get api_v1_account_messages_path(account_id: account.id, inbox_id: @other_inbox.id),
              headers: agent.create_new_auth_token

          expect(response.parsed_body['payload'].size).to eq(7)
        end
      end

      context 'when filtered by date range' do
        before do
          messages.first(5).each_with_index do |message, index|
            message.update(created_at: Time.now - index.days)
          end
        end

        it 'returns correct messages count' do
          get api_v1_account_messages_path(account_id: account.id, since: 4.days.ago.to_i, until: 2.days.ago.to_i),
              headers: agent.create_new_auth_token

          expect(response.parsed_body['payload'].size).to eq(2)
        end
      end

      context 'when filtered by team' do
        before do
          @team = create(:team, account: account)
          @other_conversation = create(:conversation, account: account, inbox: inbox, contact: contact)
          @other_messages = create_list(:message, 2, account: account, inbox: inbox, conversation: @other_conversation)
          @other_conversation.update(team: @team)
        end

        it 'returns correct messages count' do
          get api_v1_account_messages_path(account_id: account.id, team_id: @team.id),
              headers: agent.create_new_auth_token

          expect(response.parsed_body['payload'].size).to eq(4)
        end
      end

      context 'when filtered by label' do
        before do
          @label = create(:label, account: account)
          conversation.update_labels([@label.title])
        end

        it 'returns correct messages count' do
          get api_v1_account_messages_path(account_id: account.id, label: @label.title),
              headers: agent.create_new_auth_token

          expect(response.parsed_body['payload'].size).to eq(12)
        end
      end
    end
  end
end
