# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Lead Follow-up Sequences API', type: :request do
  let(:account) { create(:account) }
  let(:whatsapp_channel) { create(:channel_whatsapp, account: account) }
  let(:whatsapp_inbox) { create(:inbox, channel: whatsapp_channel, account: account) }

  describe 'GET /api/v1/accounts/{account.id}/copilot_sequences' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/copilot_sequences"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }
      let!(:sequence) { create(:lead_follow_up_sequence, account: account, inbox: whatsapp_inbox) }

      it 'returns unauthorized for agents' do
        get "/api/v1/accounts/#{account.id}/copilot_sequences",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns all sequences to administrators' do
        get "/api/v1/accounts/#{account.id}/copilot_sequences",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body, symbolize_names: true)
        expect(body.first[:id]).to eq(sequence.id)
      end

      it 'filters by inbox_id when provided' do
        other_inbox = create(:inbox, channel: create(:channel_whatsapp, account: account), account: account)
        other_sequence = create(:lead_follow_up_sequence, account: account, inbox: other_inbox)

        get "/api/v1/accounts/#{account.id}/copilot_sequences?inbox_id=#{whatsapp_inbox.id}",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body, symbolize_names: true)
        expect(body.length).to eq(1)
        expect(body.first[:id]).to eq(sequence.id)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/copilot_sequences/:id' do
    let(:sequence) { create(:lead_follow_up_sequence, account: account, inbox: whatsapp_inbox) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/copilot_sequences/#{sequence.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'returns unauthorized for agents' do
        get "/api/v1/accounts/#{account.id}/copilot_sequences/#{sequence.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'shows the sequence for administrators' do
        get "/api/v1/accounts/#{account.id}/copilot_sequences/#{sequence.id}",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body, symbolize_names: true)[:id]).to eq(sequence.id)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/copilot_sequences' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/copilot_sequences"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:administrator) { create(:user, account: account, role: :administrator) }
      let(:valid_params) do
        {
          lead_follow_up_sequence: {
            name: 'Test Sequence',
            description: 'Test description',
            inbox_id: whatsapp_inbox.id,
            active: true,
            steps: [
              {
                id: 'step_1',
                type: 'wait',
                enabled: true,
                config: {
                  delay_value: 2,
                  delay_type: 'hours'
                }
              }
            ],
            settings: {
              stop_on_contact_reply: true
            }
          }
        }
      end

      it 'creates a new sequence' do
        expect do
          post "/api/v1/accounts/#{account.id}/copilot_sequences",
               headers: administrator.create_new_auth_token,
               params: valid_params,
               as: :json
        end.to change(LeadFollowUpSequence, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it 'returns validation errors for invalid params' do
        invalid_params = {
          lead_follow_up_sequence: {
            name: '',
            inbox_id: whatsapp_inbox.id
          }
        }

        post "/api/v1/accounts/#{account.id}/copilot_sequences",
             headers: administrator.create_new_auth_token,
             params: invalid_params,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        body = JSON.parse(response.body, symbolize_names: true)
        expect(body[:errors]).to be_present
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/copilot_sequences/:id' do
    let(:sequence) { create(:lead_follow_up_sequence, account: account, inbox: whatsapp_inbox) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/copilot_sequences/#{sequence.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:administrator) { create(:user, account: account, role: :administrator) }
      let(:update_params) do
        {
          lead_follow_up_sequence: {
            name: 'Updated Name'
          }
        }
      end

      it 'updates the sequence' do
        patch "/api/v1/accounts/#{account.id}/copilot_sequences/#{sequence.id}",
              headers: administrator.create_new_auth_token,
              params: update_params,
              as: :json

        expect(response).to have_http_status(:success)
        expect(sequence.reload.name).to eq('Updated Name')
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/copilot_sequences/:id' do
    let!(:sequence) { create(:lead_follow_up_sequence, account: account, inbox: whatsapp_inbox, active: true) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/copilot_sequences/#{sequence.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'deactivates and deletes the sequence' do
        delete "/api/v1/accounts/#{account.id}/copilot_sequences/#{sequence.id}",
               headers: administrator.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:no_content)
        expect(LeadFollowUpSequence.exists?(sequence.id)).to be false
      end

      it 'deactivates sequence before deletion if active' do
        conversation = create(:conversation, account: account, inbox: whatsapp_inbox)
        follow_up = create(:conversation_follow_up,
                           conversation: conversation,
                           lead_follow_up_sequence: sequence,
                           status: 'active')

        delete "/api/v1/accounts/#{account.id}/copilot_sequences/#{sequence.id}",
               headers: administrator.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:no_content)
        expect(follow_up.reload.status).to eq('cancelled')
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/copilot_sequences/:id/activate' do
    let(:sequence) { create(:lead_follow_up_sequence, account: account, inbox: whatsapp_inbox, active: false) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/copilot_sequences/#{sequence.id}/activate"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'activates the sequence' do
        post "/api/v1/accounts/#{account.id}/copilot_sequences/#{sequence.id}/activate",
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(sequence.reload.active).to be true
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/copilot_sequences/:id/deactivate' do
    let(:sequence) { create(:lead_follow_up_sequence, account: account, inbox: whatsapp_inbox, active: true) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/copilot_sequences/#{sequence.id}/deactivate"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'deactivates the sequence' do
        post "/api/v1/accounts/#{account.id}/copilot_sequences/#{sequence.id}/deactivate",
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(sequence.reload.active).to be false
      end

      it 'cancels active follow-ups' do
        conversation = create(:conversation, account: account, inbox: whatsapp_inbox)
        follow_up = create(:conversation_follow_up,
                           conversation: conversation,
                           lead_follow_up_sequence: sequence,
                           status: 'active')

        post "/api/v1/accounts/#{account.id}/copilot_sequences/#{sequence.id}/deactivate",
             headers: administrator.create_new_auth_token,
             as: :json

        expect(follow_up.reload.status).to eq('cancelled')
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/copilot_sequences/available_templates' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/copilot_sequences/available_templates?inbox_id=#{whatsapp_inbox.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'returns available templates for WhatsApp inbox' do
        allow(whatsapp_channel).to receive(:message_templates).and_return([
                                                                             {
                                                                               'name' => 'template_1',
                                                                               'language' => 'en',
                                                                               'status' => 'APPROVED',
                                                                               'category' => 'MARKETING',
                                                                               'components' => []
                                                                             }
                                                                           ])

        get "/api/v1/accounts/#{account.id}/copilot_sequences/available_templates?inbox_id=#{whatsapp_inbox.id}",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body, symbolize_names: true)
        expect(body[:templates]).to be_present
        expect(body[:templates].first[:name]).to eq('template_1')
      end

      it 'returns error for non-WhatsApp inbox' do
        web_inbox = create(:inbox, channel: create(:channel_widget, account: account), account: account)

        get "/api/v1/accounts/#{account.id}/copilot_sequences/available_templates?inbox_id=#{web_inbox.id}",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        body = JSON.parse(response.body, symbolize_names: true)
        expect(body[:error]).to eq('Inbox must be WhatsApp')
      end
    end
  end
end
