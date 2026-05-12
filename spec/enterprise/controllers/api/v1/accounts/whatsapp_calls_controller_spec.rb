require 'rails_helper'

RSpec.describe 'WhatsApp Calls API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:channel) do
    create(:channel_whatsapp, provider: 'whatsapp_cloud', account: account,
                              validate_provider_config: false, sync_templates: false)
  end
  let(:inbox) { channel.inbox }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:call) do
    create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact,
                  provider: :whatsapp, direction: :incoming, status: 'ringing', provider_call_id: 'wacid_abc')
  end
  let(:provider_service) { instance_double(Whatsapp::Providers::WhatsappCloudService) }

  before do
    account.enable_features!('channel_voice')
    channel.provider_config = channel.provider_config.merge('source' => 'embedded_signup', 'calling_enabled' => true)
    channel.save!
    create(:inbox_member, user: agent, inbox: inbox)
    allow(Whatsapp::Providers::WhatsappCloudService).to receive(:new).and_return(provider_service)
  end

  describe 'GET /api/v1/accounts/:account_id/whatsapp_calls/:id' do
    it 'returns the call payload' do
      get "/api/v1/accounts/#{account.id}/whatsapp_calls/#{call.id}", headers: agent.create_new_auth_token

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body['id']).to eq(call.id)
      expect(body['call_id']).to eq('wacid_abc')
      expect(body['provider']).to eq('whatsapp')
    end

    it 'returns 401 when unauthenticated' do
      get "/api/v1/accounts/#{account.id}/whatsapp_calls/#{call.id}"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /api/v1/accounts/:account_id/whatsapp_calls/:id/accept' do
    it 'forwards SDP and returns the updated call payload' do
      allow(provider_service).to receive(:pre_accept_call).and_return(true)
      allow(provider_service).to receive(:accept_call).and_return(true)

      post "/api/v1/accounts/#{account.id}/whatsapp_calls/#{call.id}/accept",
           params: { sdp_answer: 'sdp_answer' }, headers: agent.create_new_auth_token

      expect(response).to have_http_status(:ok)
      expect(call.reload.status).to eq('in_progress')
    end

    it 'returns 422 when sdp_answer is missing' do
      post "/api/v1/accounts/#{account.id}/whatsapp_calls/#{call.id}/accept",
           headers: agent.create_new_auth_token

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'POST /api/v1/accounts/:account_id/whatsapp_calls/:id/reject' do
    it 'rejects the call via Meta and returns its new status' do
      allow(provider_service).to receive(:reject_call).and_return(true)

      post "/api/v1/accounts/#{account.id}/whatsapp_calls/#{call.id}/reject",
           headers: agent.create_new_auth_token

      expect(response).to have_http_status(:ok)
      expect(call.reload.status).to eq('failed')
    end
  end

  describe 'POST /api/v1/accounts/:account_id/whatsapp_calls/:id/terminate' do
    it 'terminates the call via Meta and returns its new status' do
      call.update!(status: 'in_progress')
      allow(provider_service).to receive(:terminate_call).and_return(true)

      post "/api/v1/accounts/#{account.id}/whatsapp_calls/#{call.id}/terminate",
           headers: agent.create_new_auth_token

      expect(response).to have_http_status(:ok)
      expect(call.reload.status).to eq('completed')
    end
  end

  describe 'POST /api/v1/accounts/:account_id/whatsapp_calls/initiate' do
    let(:contact) { create(:contact, account: account, phone_number: '+15551234567') }
    let!(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox, source_id: '15551234567') }
    let(:initiate_conversation) do
      create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox)
    end

    it 'creates an outbound Call and returns calling status' do
      allow(provider_service).to receive(:initiate_call).and_return({ 'calls' => [{ 'id' => 'wacid_outbound' }] })

      post "/api/v1/accounts/#{account.id}/whatsapp_calls/initiate",
           params: { conversation_id: initiate_conversation.display_id, sdp_offer: 'sdp_offer' },
           headers: agent.create_new_auth_token

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('status' => 'calling', 'call_id' => 'wacid_outbound')
      expect(Call.find_by(provider_call_id: 'wacid_outbound')).to have_attributes(direction: 'outgoing', status: 'ringing')
    end

    it 'sends a permission request and records the wamid when Meta returns NoCallPermission' do
      allow(provider_service).to receive(:initiate_call).and_raise(Voice::CallErrors::NoCallPermission)
      allow(provider_service).to receive(:send_call_permission_request).and_return({ 'messages' => [{ 'id' => 'wamid.req_xyz' }] })

      post "/api/v1/accounts/#{account.id}/whatsapp_calls/initiate",
           params: { conversation_id: initiate_conversation.display_id, sdp_offer: 'sdp_offer' },
           headers: agent.create_new_auth_token

      # Controller deliberately returns 422 so clients can't mistake the permission-template path for a successful dial.
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['status']).to eq('permission_requested')
      attrs = initiate_conversation.reload.additional_attributes
      expect(attrs['call_permission_requested_at']).to be_present
      expect(attrs['call_permission_request_message_id']).to eq('wamid.req_xyz')
    end

    it 'returns permission_request_failed when send_call_permission_request raises a transport error' do
      allow(provider_service).to receive(:initiate_call).and_raise(Voice::CallErrors::NoCallPermission)
      allow(provider_service).to receive(:send_call_permission_request).and_raise(Faraday::TimeoutError)

      post "/api/v1/accounts/#{account.id}/whatsapp_calls/initiate",
           params: { conversation_id: initiate_conversation.display_id, sdp_offer: 'sdp_offer' },
           headers: agent.create_new_auth_token

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['error']).to eq(I18n.t('errors.whatsapp.calls.permission_request_failed'))
    end

    it 'returns 422 when sdp_offer is missing' do
      post "/api/v1/accounts/#{account.id}/whatsapp_calls/initiate",
           params: { conversation_id: initiate_conversation.display_id },
           headers: agent.create_new_auth_token

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 422 when Meta raises CallFailed for non-permission errors' do
      allow(provider_service).to receive(:initiate_call).and_raise(Voice::CallErrors::CallFailed, 'Meta error')

      post "/api/v1/accounts/#{account.id}/whatsapp_calls/initiate",
           params: { conversation_id: initiate_conversation.display_id, sdp_offer: 'sdp_offer' },
           headers: agent.create_new_auth_token

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['error']).to eq('Meta error')
    end

    it 'returns 422 when the conversation contact has no phone number' do
      contact.update!(phone_number: nil)

      post "/api/v1/accounts/#{account.id}/whatsapp_calls/initiate",
           params: { conversation_id: initiate_conversation.display_id, sdp_offer: 'sdp_offer' },
           headers: agent.create_new_auth_token

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['error']).to eq(I18n.t('errors.whatsapp.calls.contact_phone_required'))
    end

    it 'returns 422 when the conversation belongs to a non-WhatsApp inbox' do
      twilio_channel = create(:channel_twilio_sms, :with_voice, account: account, phone_number: '+15551239998')
      create(:inbox_member, user: agent, inbox: twilio_channel.inbox)
      twilio_conversation = create(:conversation, account: account, inbox: twilio_channel.inbox)

      post "/api/v1/accounts/#{account.id}/whatsapp_calls/initiate",
           params: { conversation_id: twilio_conversation.display_id, sdp_offer: 'sdp_offer' },
           headers: agent.create_new_auth_token

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['error']).to eq(I18n.t('errors.whatsapp.calls.not_enabled'))
    end
  end

  describe 'POST /api/v1/accounts/:account_id/whatsapp_calls/:id/upload_recording' do
    before do
      message = create(:message, conversation: conversation, account: account, inbox: inbox,
                                 content_type: 'voice_call', message_type: 'incoming')
      call.update!(message_id: message.id)
    end

    it 'attaches the recording to the call message' do
      file = fixture_file_upload(Rails.root.join('spec/assets/sample.mp3'), 'audio/mpeg')

      expect do
        post "/api/v1/accounts/#{account.id}/whatsapp_calls/#{call.id}/upload_recording",
             params: { recording: file }, headers: agent.create_new_auth_token
      end.to change { call.message.attachments.count }.by(1)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['status']).to eq('uploaded')
    end

    it 'is idempotent: returns already_uploaded if an audio attachment exists' do
      call.message.attachments.create!(account_id: account.id, file_type: :audio,
                                       file: fixture_file_upload(Rails.root.join('spec/assets/sample.mp3'), 'audio/mpeg'))

      post "/api/v1/accounts/#{account.id}/whatsapp_calls/#{call.id}/upload_recording",
           params: { recording: fixture_file_upload(Rails.root.join('spec/assets/sample.mp3'), 'audio/mpeg') },
           headers: agent.create_new_auth_token

      expect(response.parsed_body['status']).to eq('already_uploaded')
    end
  end
end
