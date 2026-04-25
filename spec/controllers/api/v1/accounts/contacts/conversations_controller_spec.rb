require 'rails_helper'

RSpec.describe '/api/v1/accounts/{account.id}/contacts/:id/conversations', type: :request do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account) }
  let(:inbox_1) { create(:inbox, account: account) }
  let(:inbox_2) { create(:inbox, account: account) }
  let(:contact_inbox_1) { create(:contact_inbox, contact: contact, inbox: inbox_1) }
  let(:contact_inbox_2) { create(:contact_inbox, contact: contact, inbox: inbox_2) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:unknown) { create(:user, account: account, role: nil) }

  before do
    create(:inbox_member, user: agent, inbox: inbox_1)
    2.times.each do
      create(:conversation, account: account, inbox: inbox_1, contact: contact, contact_inbox: contact_inbox_1)
      create(:conversation, account: account, inbox: inbox_2, contact: contact, contact_inbox: contact_inbox_2)
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/contacts/:id/conversations' do
    context 'when unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/conversations"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is logged in' do
      context 'with user as administrator' do
        it 'returns conversations from all inboxes' do
          get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/conversations", headers: admin.create_new_auth_token

          expect(response).to have_http_status(:success)
          json_response = response.parsed_body

          expect(json_response['payload'].length).to eq 4
        end
      end

      context 'with user as agent' do
        it 'returns conversations from the inboxes which agent has access to' do
          get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/conversations", headers: agent.create_new_auth_token

          expect(response).to have_http_status(:success)
          json_response = response.parsed_body

          expect(json_response['payload'].length).to eq 2
        end
      end

      context 'with user as unknown role' do
        it 'returns conversations from no inboxes' do
          get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/conversations", headers: unknown.create_new_auth_token

          expect(response).to have_http_status(:success)
          json_response = response.parsed_body

          expect(json_response['payload'].length).to eq 0
        end
      end
    end
  end
end

describe 'POST /api/v1/accounts/:account_id/contacts/:id/conversations' do
  let(:whatsapp_inbox) do
    create(:inbox, account: account, channel: create(:channel_whatsapp),
                   lock_to_single_conversation: true)
  end

  context 'when inbox has reopen existing conversation enabled' do
    let!(:existing_conversation) do
      create(:conversation, contact: contact, inbox: whatsapp_inbox,
                            account: account, status: :resolved,
                            last_activity_at: 1.hour.ago)
    end

    it 'reopens the existing resolved conversation instead of creating a new one' do
      expect do
        post "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/conversations",
             params: { inbox_id: whatsapp_inbox.id },
             headers: agent.create_new_auth_token,
             as: :json
      end.not_to change(Conversation, :count)

      expect(existing_conversation.reload.status).to eq('open')
    end
  end

  context 'when inbox does NOT have reopen existing conversation enabled' do
    let(:regular_inbox) { create(:inbox, account: account, lock_to_single_conversation: false) }

    it 'creates a new conversation regardless' do
      expect do
        post "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/conversations",
             params: { inbox_id: regular_inbox.id },
             headers: agent.create_new_auth_token,
             as: :json
      end.to change(Conversation, :count).by(1)
    end
  end

  context 'when no resolved conversation exists for the contact' do
    it 'creates a new conversation' do
      expect do
        post "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/conversations",
             params: { inbox_id: whatsapp_inbox.id },
             headers: agent.create_new_auth_token,
             as: :json
      end.to change(Conversation, :count).by(1)
    end
  end
end