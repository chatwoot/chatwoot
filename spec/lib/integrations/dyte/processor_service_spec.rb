require 'rails_helper'

describe Integrations::Dyte::ProcessorService do
  let(:headers) { { 'Content-Type' => 'application/json' } }
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, status: :pending) }
  let(:processor) { described_class.new(account: account, conversation: conversation) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:dyte_settings) { { account_id: 'account_id', app_id: 'app_id', api_token: 'api_token' } }
  let(:integration_message) do
    create(:message, content_type: 'integrations',
                     content_attributes: { type: 'dyte', data: { meeting_id: 'm_id' } },
                     conversation: conversation)
  end

  before do
    allow(Integrations::Cloudflare::RealtimeKitCredentialsValidator).to receive(:validate)
      .and_return(Integrations::Cloudflare::RealtimeKitCredentialsValidator::Result.new(true, nil))

    hook = build(:integrations_hook, :dyte, account: account, settings: dyte_settings)
    hook.save!(validate: false) if dyte_settings[:organization_id].present?
    hook.save! unless hook.persisted?
  end

  describe '#create_a_meeting' do
    context 'when the API response is success' do
      before do
        stub_request(:post, 'https://api.cloudflare.com/client/v4/accounts/account_id/realtime/kit/app_id/meetings')
          .to_return(
            status: 200,
            body: { success: true, data: { id: 'meeting_id' } }.to_json,
            headers: headers
          )
      end

      it 'creates an integration message in the conversation' do
        response = processor.create_a_meeting(agent)
        expect(response[:content]).to eq("#{agent.available_name} has started a meeting")
        expect(conversation.reload.messages.last.content_type).to eq('integrations')
      end
    end

    context 'when the API response is errored' do
      before do
        stub_request(:post, 'https://api.cloudflare.com/client/v4/accounts/account_id/realtime/kit/app_id/meetings')
          .to_return(
            status: 422,
            body: { success: false, data: { message: 'Title is required' } }.to_json,
            headers: headers
          )
      end

      it 'does not create an integration message in the conversation' do
        response = processor.create_a_meeting(agent)
        expect(response).to eq({ error: { 'data' => { 'message' => 'Title is required' }, 'success' => false }, error_code: 422 })
        expect(conversation.reload.messages.count).to eq(0)
      end
    end

    context 'when the stored hook still has legacy Dyte credentials' do
      let(:dyte_settings) { { organization_id: 'org_id', api_key: 'dyte_api_key' } }

      it 'returns a normal error response without creating a RealtimeKit client' do
        expect(Dyte).not_to receive(:new)

        response = processor.create_a_meeting(agent)

        expect(response).to eq({ error: I18n.t('errors.dyte.realtimekit_credentials_required') })
        expect(conversation.reload.messages.count).to eq(0)
      end
    end
  end

  describe '#add_participant_to_meeting' do
    context 'when the API response is success' do
      before do
        stub_request(:post, 'https://api.cloudflare.com/client/v4/accounts/account_id/realtime/kit/app_id/meetings/m_id/participants')
          .to_return(
            status: 200,
            body: { success: true, data: { id: 'random_uuid', token: 'json-web-token' } }.to_json,
            headers: headers
          )
      end

      it 'return the authResponse' do
        response = processor.add_participant_to_meeting('m_id', agent)
        expect(response).not_to be_nil
      end

      it 'stores the RealtimeKit participant ID on the integration message' do
        response = processor.add_participant_to_meeting('m_id', agent, integration_message)

        expect(response).not_to be_nil
        expect(integration_message.reload.content_attributes.dig('data', 'participants', "User:#{agent.id}")).to eq('random_uuid')
      end

      it 'sends a namespaced participant ID to RealtimeKit' do
        processor.add_participant_to_meeting('m_id', agent, integration_message)

        expect(WebMock).to(
          have_requested(:post, 'https://api.cloudflare.com/client/v4/accounts/account_id/realtime/kit/app_id/meetings/m_id/participants')
            .with { |request| JSON.parse(request.body)['custom_participant_id'] == "User:#{agent.id}" }
        )
      end
    end

    context 'when the participant ID is already stored on the integration message' do
      let(:integration_message) do
        create(:message, content_type: 'integrations',
                         content_attributes: { type: 'dyte', data: { meeting_id: 'm_id', participants: { "User:#{agent.id}" => 'participant_id' } } },
                         conversation: conversation)
      end

      before do
        stub_request(:post, 'https://api.cloudflare.com/client/v4/accounts/account_id/realtime/kit/app_id/meetings/m_id/participants/participant_id/token')
          .to_return(
            status: 200,
            body: { success: true, data: { token: 'refreshed-json-web-token' } }.to_json,
            headers: headers
          )
      end

      it 'returns a refreshed participant token without creating the participant again' do
        response = processor.add_participant_to_meeting('m_id', agent, integration_message)

        expect(response).to eq({ 'token' => 'refreshed-json-web-token' })
        expect(WebMock).not_to have_requested(
          :post, 'https://api.cloudflare.com/client/v4/accounts/account_id/realtime/kit/app_id/meetings/m_id/participants'
        )
      end
    end

    context 'when the participant exists in RealtimeKit but is not stored on the integration message' do
      before do
        stub_request(:post, 'https://api.cloudflare.com/client/v4/accounts/account_id/realtime/kit/app_id/meetings/m_id/participants')
          .to_return(
            status: 422,
            body: { success: false, error: 'Participant already exists' }.to_json,
            headers: headers
          )
        stub_request(:get, 'https://api.cloudflare.com/client/v4/accounts/account_id/realtime/kit/app_id/meetings/m_id/participants')
          .to_return(
            status: 200,
            body: { success: true, data: [{ id: 'participant_id', custom_participant_id: "User:#{agent.id}" }] }.to_json,
            headers: headers
          )
        stub_request(:post, 'https://api.cloudflare.com/client/v4/accounts/account_id/realtime/kit/app_id/meetings/m_id/participants/participant_id/token')
          .to_return(
            status: 200,
            body: { success: true, data: { token: 'refreshed-json-web-token' } }.to_json,
            headers: headers
          )
      end

      it 'finds the existing participant and stores the RealtimeKit participant ID' do
        response = processor.add_participant_to_meeting('m_id', agent, integration_message)

        expect(response).to eq({ 'token' => 'refreshed-json-web-token' })
        expect(integration_message.reload.content_attributes.dig('data', 'participants', "User:#{agent.id}")).to eq('participant_id')
      end
    end

    context 'when a contact and agent have the same database ID' do
      let(:contact) { create(:contact, account: account) }

      before do
        allow(contact).to receive(:id).and_return(agent.id)
        stub_request(:post, 'https://api.cloudflare.com/client/v4/accounts/account_id/realtime/kit/app_id/meetings/m_id/participants')
          .to_return(
            status: 200,
            body: { success: true, data: { id: 'contact_participant_id', token: 'json-web-token' } }.to_json,
            headers: headers
          )
      end

      it 'stores the contact participant separately from the agent participant' do
        integration_message.update!(
          content_attributes: { type: 'dyte', data: { meeting_id: 'm_id', participants: { "User:#{agent.id}" => 'agent_participant_id' } } }
        )

        response = processor.add_participant_to_meeting('m_id', contact, integration_message)

        expect(response).to eq({ 'id' => 'contact_participant_id', 'token' => 'json-web-token' })
        participants = integration_message.reload.content_attributes.dig('data', 'participants')
        expect(participants["User:#{agent.id}"]).to eq('agent_participant_id')
        expect(participants["Contact:#{contact.id}"]).to eq('contact_participant_id')
      end
    end

    context 'when the stored hook still has legacy Dyte credentials' do
      let(:dyte_settings) { { organization_id: 'org_id', api_key: 'dyte_api_key' } }

      it 'returns a normal error response without creating a RealtimeKit client' do
        expect(Dyte).not_to receive(:new)

        response = processor.add_participant_to_meeting('m_id', agent)

        expect(response).to eq({ error: I18n.t('errors.dyte.realtimekit_credentials_required') })
      end
    end
  end
end
