require 'rails_helper'

RSpec.describe Voice::Captain::CallStarter do
  let(:account) { create(:account, limits: { 'captain_responses' => 10 }) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account, phone_number: '+15551230099') }
  let(:inbox) { channel.inbox }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:call_sid) { "CA#{SecureRandom.hex(16)}" }
  let(:from) { '+15550007777' }
  let(:vapi_call_id) { "vapi_#{SecureRandom.hex(8)}" }
  let(:vapi_twiml) { '<Response><Connect><Stream url="wss://vapi.example/stream"/></Connect></Response>' }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(16)}"))
    account.enable_features!('captain_integration')
    { 'CAPTAIN_VAPI_API_KEY' => 'vapi-key', 'CAPTAIN_VAPI_PHONE_NUMBER_ID' => 'pn_123', 'CAPTAIN_VAPI_WEBHOOK_SECRET' => 'hook-secret' }
      .each { |name, value| create(:installation_config, name: name, value: value) }
    create(:captain_inbox, captain_assistant: assistant, inbox: inbox)
    channel.update!(provider_config: channel.provider_config.merge('captain_answers_calls' => true))
  end

  def stub_vapi(status: 200, body: { id: vapi_call_id, phoneCallProviderDetails: { twiml: vapi_twiml } })
    stub_request(:post, Voice::Captain::VapiClient::API_URL).to_return(
      status: status, body: body.to_json, headers: { 'Content-Type' => 'application/json' }
    )
  end

  describe '.eligible?' do
    it 'is true for a new call on an inbox where Captain answers calls' do
      expect(described_class.eligible?(inbox: inbox.reload, call_sid: call_sid)).to be(true)
    end

    it 'is false when the inbox switch is off' do
      channel.update!(provider_config: channel.provider_config.merge('captain_answers_calls' => false))

      expect(described_class.eligible?(inbox: inbox.reload, call_sid: call_sid)).to be(false)
    end

    it 'is false until Vapi is set up in Super Admin' do
      InstallationConfig.find_by(name: 'CAPTAIN_VAPI_API_KEY').update!(value: '')

      expect(described_class.eligible?(inbox: inbox.reload, call_sid: call_sid)).to be(false)
    end

    it 'is false once the call was offered to Captain, so a handoff redirect rings agents' do
      Voice::Captain::CallSession.mark_twilio_call!(call_sid)

      expect(described_class.eligible?(inbox: inbox.reload, call_sid: call_sid)).to be(false)
    end
  end

  describe '#perform' do
    subject(:perform) { described_class.new(inbox: inbox.reload, call_sid: call_sid, from: from).perform }

    it 'creates a Vapi call for a pending conversation and returns its TwiML' do
      request = stub_vapi

      twiml = perform

      conversation = inbox.conversations.last
      session = Voice::Captain::CallSession.for_vapi_call(vapi_call_id)
      expect(twiml).to eq(vapi_twiml)
      expect(conversation).to be_pending
      expect(conversation.contact.phone_number).to eq(from)
      expect(session.conversation_id).to eq(conversation.id)
      expect(session.twilio_call_sid).to eq(call_sid)
      expect(request.with { |req| JSON.parse(req.body).values_at('phoneNumberId', 'phoneCallProviderBypassEnabled') == ['pn_123', true] })
        .to have_been_made
    end

    it "speaks with the inbox's chosen voice" do
      request = stub_vapi
      channel.update!(provider_config: channel.provider_config.merge('captain_voice' => 'Sagar'))

      perform

      expect(request.with { |req| JSON.parse(req.body).dig('assistant', 'voice', 'voiceId') == 'Sagar' }).to have_been_made
    end

    it 'speaks with Elliot until a voice is chosen' do
      request = stub_vapi

      perform

      expect(request.with { |req| JSON.parse(req.body).dig('assistant', 'voice', 'voiceId') == 'Elliot' }).to have_been_made
    end

    it 'returns nil and marks the call when Vapi fails, so agents are rung' do
      stub_vapi(status: 500, body: { error: 'boom' })

      expect(perform).to be_nil
      expect(Voice::Captain::CallSession.twilio_call_marked?(call_sid)).to be(true)
    end

    it 'leaves a conversation an agent already holds with the agent' do
      request = stub_vapi
      contact_inbox = create(:contact_inbox, inbox: inbox, source_id: from)
      create(:conversation, account: account, inbox: inbox, contact: contact_inbox.contact, contact_inbox: contact_inbox).update!(status: :open)

      expect(perform).to be_nil
      expect(request).not_to have_been_made
    end

    context 'when the assistant answers only during business hours and the inbox is closed' do
      before do
        assistant.update!(config: assistant.config.merge('response_window' => 'business_hours'))
        inbox.update!(working_hours_enabled: true)
        inbox.working_hours.update_all(closed_all_day: true) # rubocop:disable Rails/SkipsModelValidations
      end

      it 'rings agents for a new caller' do
        request = stub_vapi

        expect(perform).to be_nil
        expect(request).not_to have_been_made
        expect(inbox.conversations.last).to be_open
      end

      it 'hands a conversation Captain was holding to the team' do
        request = stub_vapi
        contact_inbox = create(:contact_inbox, inbox: inbox, source_id: from)
        conversation = create(:conversation, account: account, inbox: inbox, contact: contact_inbox.contact, contact_inbox: contact_inbox)
        conversation.update_columns(status: Conversation.statuses[:pending]) # rubocop:disable Rails/SkipsModelValidations

        expect(perform).to be_nil
        expect(request).not_to have_been_made
        expect(conversation.reload).to be_open
      end
    end

    it 'rings agents for a withheld number' do
      request = stub_vapi

      result = described_class.new(inbox: inbox.reload, call_sid: call_sid, from: '+266696687').perform

      expect(result).to be_nil
      expect(request).not_to have_been_made
    end
  end
end
