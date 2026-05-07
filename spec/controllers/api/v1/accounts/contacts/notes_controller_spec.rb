require 'rails_helper'

RSpec.describe 'Notes API', type: :request do
  let!(:account) { create(:account) }
  let!(:contact) { create(:contact, account: account) }
  let!(:administrator) { create(:user, account: account, role: :administrator) }
  let!(:note) { create(:note, contact: contact, account: account, user: administrator) }
  let!(:agent) { create(:user, account: account, role: :agent) }

  describe 'GET /api/v1/accounts/{account.id}/contacts/{contact.id}/notes' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/notes"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns all notes to agents' do
        get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/notes",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body, symbolize_names: true)
        expect(body.first[:content]).to eq(note.content)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/contacts/{contact.id}/notes/{note.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/notes/#{note.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'shows the note for agents' do
        get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/notes/#{note.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body, symbolize_names: true)[:id]).to eq(note.id)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/contacts/{contact.id}/notes' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/notes",
             params: { content: 'test message' },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'creates a new note' do
        post "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/notes",
             params: { content: 'test note' },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body, symbolize_names: true)[:content]).to eq('test note')
      end

      it 'persists note timeline metadata' do
        post "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/notes",
             params: {
               note: {
                 content: 'Customer prefers Monday follow ups',
                 metadata: { agent_context: { topic: 'follow_up' } }
               }
             },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body, symbolize_names: true)
        created_note = Note.find(body[:id])

        expect(created_note.user).to eq(agent)
        expect(created_note.updated_by).to eq(agent)
        expect(created_note.contact).to eq(contact)
        expect(created_note.content).to eq('Customer prefers Monday follow ups')
        expect(created_note.source).to eq('manual')
        expect(created_note.metadata).to eq({ 'agent_context' => { 'topic' => 'follow_up' } })
      end

      it 'returns note timeline metadata' do
        post "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/notes",
             params: {
               note: {
                 content: 'Customer prefers Monday follow ups',
                 metadata: { agent_context: { topic: 'follow_up' } }
               }
             },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body, symbolize_names: true)

        expect(body[:created_by][:id]).to eq(agent.id)
        expect(body[:updated_by][:id]).to eq(agent.id)
        expect(body[:target]).to eq({ type: 'contact', id: contact.id })
        expect(body[:source]).to eq('manual')
        expect(body[:metadata]).to eq({ agent_context: { topic: 'follow_up' } })
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/contacts/{contact.id}/notes/:id' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/notes/#{note.id}",
              params: { content: 'test message' },
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'updates the note' do
        patch "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/notes/#{note.id}",
              params: { content: 'test message' },
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body, symbolize_names: true)[:content]).to eq('test message')
      end

      it 'updates content through PATCH without changing the creator' do
        patch "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/notes/#{note.id}",
              params: { content: 'Edited by the agent' },
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)

        body = JSON.parse(response.body, symbolize_names: true)
        expect(body[:content]).to eq('Edited by the agent')
        expect(body[:created_by][:id]).to eq(administrator.id)
        expect(body[:updated_by][:id]).to eq(agent.id)
        expect(note.reload.user).to eq(administrator)
        expect(note.updated_by).to eq(agent)
      end

      it 'accepts nested note params for PATCH' do
        patch "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/notes/#{note.id}",
              params: { note: { content: 'Nested edit', metadata: { agent_context: { priority: 'high' } } } },
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body, symbolize_names: true)
        expect(body[:content]).to eq('Nested edit')
        expect(body[:metadata]).to eq({ agent_context: { priority: 'high' } })
      end

      it 'does not update a note belonging to another contact' do
        other_contact = create(:contact, account: account)
        other_note = create(:note, account: account, contact: other_contact)
        original_content = other_note.content

        patch "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/notes/#{other_note.id}",
              params: { content: 'Wrong contact edit' },
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:not_found)
        expect(other_note.reload.content).to eq(original_content)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/notes/:id' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/notes/#{note.id}",
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'delete note if agent' do
        delete "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/notes/#{note.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(Note.exists?(note.id)).to be false
      end
    end
  end
end
