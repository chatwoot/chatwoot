require 'rails_helper'

RSpec.describe 'Enterprise Conversation Messages API', type: :request do
  let!(:account) { create(:account) }

  describe 'DELETE /api/v1/accounts/{account.id}/conversations/:conversation_id/messages/:id' do
    let(:message) { create(:message, account: account, content: 'Secret original content') }
    let(:conversation) { message.conversation }
    let(:agent) { create(:user, account: account, role: :agent) }

    before do
      create(:inbox_member, inbox: conversation.inbox, user: agent)
    end

    it 'soft deletes the message and records an audit log with the original content' do
      expect do
        delete "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{message.id}",
               headers: agent.create_new_auth_token,
               as: :json
      end.to change(Enterprise::AuditLog, :count).by(1)

      audit_log = Enterprise::AuditLog.where(auditable_type: 'Message', action: 'destroy').last

      aggregate_failures do
        expect(response).to have_http_status(:success)
        expect(message.reload.content).to eq 'This message was deleted'
        expect(message.reload.deleted).to be true
        expect(audit_log.auditable_id).to eq(message.id)
        expect(audit_log.user_id).to eq(agent.id)
        expect(audit_log.associated_id).to eq(account.id)
        expect(audit_log.remote_address).to be_present
        expect(audit_log.audited_changes['content']).to eq('Secret original content')
        expect(audit_log.audited_changes['conversation_id']).to eq(message.conversation_id)
        expect(audit_log.audited_changes['display_id']).to eq(conversation.display_id)
        expect(audit_log.audited_changes['inbox_id']).to eq(message.inbox_id)
      end
    end

    it 'does not create an audit log when the message id is invalid' do
      expect do
        delete "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/99999",
               headers: agent.create_new_auth_token,
               as: :json
      end.not_to change(Enterprise::AuditLog, :count)

      expect(response).to have_http_status(:not_found)
    end

    it 'does not create a duplicate audit log when an already-deleted message is deleted again' do
      path = "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{message.id}"

      delete path, headers: agent.create_new_auth_token, as: :json
      expect(Enterprise::AuditLog.where(auditable_type: 'Message', action: 'destroy').count).to eq(1)

      expect do
        delete path, headers: agent.create_new_auth_token, as: :json
      end.not_to change(Enterprise::AuditLog, :count)
    end
  end
end
