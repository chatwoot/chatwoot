require 'rails_helper'

RSpec.describe '/api/v1/accounts/:account_id/conversations/:conversation_id/direct_uploads', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:contact) { create(:contact, account: account, email: nil) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let(:conversation) { create(:conversation, contact: contact, account: account, inbox: web_widget.inbox, contact_inbox: contact_inbox) }

  describe 'POST /api/v1/accounts/:account_id/conversations/:conversation_id/direct_uploads' do
    context 'when post request is made' do
      it 'creates attachment message in conversation' do
        contact

        post api_v1_account_conversation_direct_uploads_path(account_id: account.id, conversation_id: conversation.display_id),
             params: {
               blob: {
                 filename: 'avatar.png',
                 byte_size: '1234',
                 checksum: 'dsjbsdhbfif3874823mnsdbf',
                 content_type: 'image/png'
               }
             },
             headers: { api_access_token: agent.access_token.token },
             as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['content_type']).to eq('image/png')
      end
    end
  end
end
