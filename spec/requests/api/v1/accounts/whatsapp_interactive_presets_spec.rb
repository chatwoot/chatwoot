require 'rails_helper'

RSpec.describe 'WhatsApp interactive presets API', type: :request do
  let(:account) { create(:account) }
  let(:creator) { create(:user, account: account, role: :agent) }
  let(:other_agent) { create(:user, account: account, role: :agent) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:definition) do
    {
      schema_version: 1,
      type: 'button',
      body: { text: 'Choose an option' },
      action: { buttons: [{ title: 'Continue' }] }
    }
  end
  let!(:preset) do
    create(:whatsapp_interactive_preset, account: account, created_by: creator, name: 'Welcome menu', definition: definition)
  end
  let(:base_path) { "/api/v1/accounts/#{account.id}/whatsapp_interactive_presets" }

  describe 'GET /api/v1/accounts/:account_id/whatsapp_interactive_presets' do
    it 'returns a flat searchable account collection with creator and permissions' do
      create(:whatsapp_interactive_preset, account: account, created_by: other_agent, name: 'Unrelated')

      get base_path, params: { search: 'welcome' }, headers: other_agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['payload'].length).to eq(1)
      expect(response.parsed_body.dig('payload', 0)).to include(
        'id' => preset.id,
        'name' => 'Welcome menu',
        'interactive_type' => 'button',
        'creator' => { 'id' => creator.id, 'name' => creator.name },
        'permissions' => { 'update' => false, 'delete' => false }
      )
    end

    it 'does not expose presets from another account' do
      foreign_account = create(:account)
      foreign_creator = create(:user, account: foreign_account)
      foreign_preset = create(:whatsapp_interactive_preset, account: foreign_account, created_by: foreign_creator)

      get base_path, headers: other_agent.create_new_auth_token, as: :json
      expect(response.parsed_body['payload'].pluck('id')).not_to include(foreign_preset.id)

      get "#{base_path}/#{foreign_preset.id}", headers: other_agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/accounts/:account_id/whatsapp_interactive_presets' do
    it 'lets another agent create an independently owned copy' do
      original_definition = preset.definition.deep_dup

      post base_path,
           params: { name: 'My copy', definition: preset.definition.merge('body' => { 'text' => 'Customized' }) },
           headers: other_agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('name' => 'My copy', 'creator' => { 'id' => other_agent.id, 'name' => other_agent.name })
      expect(preset.reload.definition).to eq(original_definition)
      expect(account.whatsapp_interactive_presets.last.created_by).to eq(other_agent)
    end

    it 'saves valid definitions without a conversation and rejects malformed or forged fields' do
      expect do
        post base_path, params: { name: 'No conversation', definition: definition }, headers: creator.create_new_auth_token, as: :json
      end.to change(account.whatsapp_interactive_presets, :count).by(1)
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig('definition', 'action', 'buttons', 0)).not_to have_key('delivery_id')

      forged_definition = definition.deep_merge(action: { buttons: [{ title: 'Continue', delivery_id: 'raw-id' }] })
      post base_path, params: { name: 'Forged', definition: forged_definition }, headers: creator.create_new_auth_token, as: :json
      expect(response).to have_http_status(:unprocessable_entity)

      post base_path,
           params: { name: 'Forged owner', definition: definition, created_by_id: other_agent.id, interactive_type: 'list' },
           headers: creator.create_new_auth_token,
           as: :json
      expect(response).to have_http_status(:unprocessable_entity)

      invalid_definitions = [
        definition.merge(type: 'unknown'),
        definition.merge(schema_version: 2),
        definition.deep_merge(body: { text: 'x' * 1025 }),
        definition.deep_merge(action: { buttons: [{ title: 'Continue', meta_payload: {} }] })
      ]
      invalid_definitions.each_with_index do |invalid_definition, index|
        post base_path,
             params: { name: "Invalid #{index}", definition: invalid_definition },
             headers: creator.create_new_auth_token,
             as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/:account_id/whatsapp_interactive_presets/:id' do
    it 'allows only the creator to update, including against administrators' do
      patch "#{base_path}/#{preset.id}", params: { name: 'Other edit' }, headers: other_agent.create_new_auth_token, as: :json
      expect(response).to have_http_status(:unauthorized)

      patch "#{base_path}/#{preset.id}", params: { name: 'Admin edit' }, headers: administrator.create_new_auth_token, as: :json
      expect(response).to have_http_status(:unauthorized)

      patch "#{base_path}/#{preset.id}", params: { name: 'Creator edit' }, headers: creator.create_new_auth_token, as: :json
      expect(response).to have_http_status(:ok)
      expect(preset.reload.name).to eq('Creator edit')
    end

    it 'keeps a membership orphan readable, copyable, read-only, and administrator-deletable' do
      account.account_users.find_by!(user: creator).destroy!

      get "#{base_path}/#{preset.id}", headers: other_agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        'creator' => { 'id' => nil, 'name' => 'Former agent' },
        'permissions' => { 'update' => false, 'delete' => false }
      )

      post base_path,
           params: { name: 'Orphan copy', definition: preset.definition },
           headers: other_agent.create_new_auth_token,
           as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['creator']).to eq('id' => other_agent.id, 'name' => other_agent.name)

      delete "#{base_path}/#{preset.id}", headers: administrator.create_new_auth_token, as: :json
      expect(response).to have_http_status(:no_content)
    end

    it 'reports Former agent and permits administrator deletion after the creator user is deleted' do
      creator.destroy!

      get "#{base_path}/#{preset.id}", headers: administrator.create_new_auth_token, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['creator']).to eq('id' => nil, 'name' => 'Former agent')

      delete "#{base_path}/#{preset.id}", headers: administrator.create_new_auth_token, as: :json
      expect(response).to have_http_status(:no_content)
    end
  end

  describe 'DELETE /api/v1/accounts/:account_id/whatsapp_interactive_presets/:id' do
    it 'allows only an administrator and leaves unrelated message snapshots and assets unchanged' do
      message = create(:message, :with_attachment, account: account, content_attributes: { 'whatsapp_interactive' => definition })
      attachment_id = message.attachments.first.id
      snapshot = message.content_attributes.deep_dup

      delete "#{base_path}/#{preset.id}", headers: creator.create_new_auth_token, as: :json
      expect(response).to have_http_status(:unauthorized)

      delete "#{base_path}/#{preset.id}", headers: administrator.create_new_auth_token, as: :json
      expect(response).to have_http_status(:no_content)
      expect { preset.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(message.reload.content_attributes).to eq(snapshot)
      expect(Attachment.exists?(attachment_id)).to be(true)
    end
  end
end
