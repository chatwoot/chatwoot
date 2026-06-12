require 'rails_helper'

RSpec.describe 'Reusable Attachments API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:other_agent) { create(:user, account: account, role: :agent) }

  def create_reusable_attachment(created_by: nil, name: 'Template')
    attachment = account.reusable_attachments.new(name: name, created_by: created_by)
    attachment.file.attach(
      io: Rails.root.join('spec/assets/avatar.png').open,
      filename: 'avatar.png',
      content_type: 'image/png'
    )
    attachment.save!
    attachment
  end

  describe 'GET /api/v1/accounts/{account.id}/reusable_attachments' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/reusable_attachments"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      it 'returns all reusable attachments in the account' do
        create_reusable_attachment(created_by: admin)

        get "/api/v1/accounts/#{account.id}/reusable_attachments",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body.length).to eq(1)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/reusable_attachments' do
    let(:file) { Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/avatar.png'), 'image/png') }

    context 'when it is an authenticated agent' do
      it 'creates the reusable attachment with the current user as creator' do
        expect do
          post "/api/v1/accounts/#{account.id}/reusable_attachments",
               headers: agent.create_new_auth_token,
               params: { name: 'Contract 2024', file: file }
        end.to change(ReusableAttachment, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(ReusableAttachment.last.created_by).to eq(agent)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/reusable_attachments/:id' do
    let!(:reusable_attachment) { create_reusable_attachment(created_by: agent) }

    context 'when it is an administrator' do
      it 'updates any reusable attachment' do
        patch "/api/v1/accounts/#{account.id}/reusable_attachments/#{reusable_attachment.id}",
              headers: admin.create_new_auth_token,
              params: { name: 'Updated by admin' }

        expect(response).to have_http_status(:success)
        expect(reusable_attachment.reload.name).to eq('Updated by admin')
      end
    end

    context 'when it is the agent who created it' do
      it 'updates the reusable attachment' do
        patch "/api/v1/accounts/#{account.id}/reusable_attachments/#{reusable_attachment.id}",
              headers: agent.create_new_auth_token,
              params: { name: 'Updated by author' }

        expect(response).to have_http_status(:success)
        expect(reusable_attachment.reload.name).to eq('Updated by author')
      end
    end

    context 'when it is another agent' do
      it 'returns unauthorized and does not update the reusable attachment' do
        patch "/api/v1/accounts/#{account.id}/reusable_attachments/#{reusable_attachment.id}",
              headers: other_agent.create_new_auth_token,
              params: { name: 'HIJACKED' }

        expect(response).to have_http_status(:unauthorized)
        expect(reusable_attachment.reload.name).to eq('Template')
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/reusable_attachments/:id' do
    let!(:reusable_attachment) { create_reusable_attachment(created_by: agent) }

    context 'when it is an administrator' do
      it 'deletes any reusable attachment' do
        expect do
          delete "/api/v1/accounts/#{account.id}/reusable_attachments/#{reusable_attachment.id}",
                 headers: admin.create_new_auth_token
        end.to change(ReusableAttachment, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end
    end

    context 'when it is the agent who created it' do
      it 'deletes the reusable attachment' do
        expect do
          delete "/api/v1/accounts/#{account.id}/reusable_attachments/#{reusable_attachment.id}",
                 headers: agent.create_new_auth_token
        end.to change(ReusableAttachment, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end
    end

    context 'when it is another agent' do
      it 'returns unauthorized and does not delete the reusable attachment' do
        expect do
          delete "/api/v1/accounts/#{account.id}/reusable_attachments/#{reusable_attachment.id}",
                 headers: other_agent.create_new_auth_token
        end.not_to change(ReusableAttachment, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
