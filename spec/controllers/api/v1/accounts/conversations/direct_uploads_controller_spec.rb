require 'rails_helper'

RSpec.describe '/api/v1/accounts/:account_id/conversations/:conversation_id/direct_uploads', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:contact) { create(:contact, account: account, email: nil) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let(:conversation) { create(:conversation, contact: contact, account: account, inbox: web_widget.inbox, contact_inbox: contact_inbox) }
  let(:blob_params) do
    {
      blob: {
        filename: 'avatar.png',
        byte_size: '1234',
        checksum: 'dsjbsdhbfif3874823mnsdbf',
        content_type: 'image/png'
      }
    }
  end

  def upload(headers: {})
    post api_v1_account_conversation_direct_uploads_path(account_id: account.id, conversation_id: conversation.display_id),
         params: blob_params,
         headers: headers,
         as: :json
  end

  describe 'POST /api/v1/accounts/:account_id/conversations/:conversation_id/direct_uploads' do
    context 'with a valid full-scope access token' do
      it 'creates the direct upload blob' do
        expect { upload(headers: { api_access_token: agent.access_token.token }) }
          .to change(ActiveStorage::Blob, :count).by(1)

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['content_type']).to eq('image/png')
      end
    end

    context 'without an access token' do
      it 'returns unauthorized without creating a blob' do
        expect { upload }.not_to change(ActiveStorage::Blob, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with an invalid access token' do
      it 'returns unauthorized without creating a blob' do
        expect { upload(headers: { api_access_token: 'invalid-token' }) }
          .not_to change(ActiveStorage::Blob, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with a read-only access token' do
      it 'returns forbidden without creating a blob' do
        expect { upload(headers: { api_access_token: agent.read_only_access_token.token }) }
          .not_to change(ActiveStorage::Blob, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
