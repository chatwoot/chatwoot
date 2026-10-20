require 'rails_helper'

RSpec.describe Voice::EndUnansweredCallService do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account, phone_number: '+15551239999') }
  let(:inbox) { channel.inbox }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:call) { create(:call, conversation: conversation, status: 'ringing') }
  let(:conference) { instance_double(Voice::Provider::Twilio::ConferenceService, agents_remain?: false) }
  let(:twilio_call) { instance_double(Twilio::REST::Api::V2010::AccountContext::CallContext) }
  let(:twilio_client) { instance_double(Twilio::REST::Client, calls: twilio_call) }
  let(:sent_twiml) { [] }
  let(:service) { described_class.new(call: call) }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(8)}"))
    allow(Voice::Provider::Twilio::ConferenceService).to receive(:new).and_return(conference)
    allow(Twilio::REST::Client).to receive(:new).and_return(twilio_client)
    allow(twilio_call).to receive(:update) { |twiml:| sent_twiml << twiml }
    allow(ActionCable.server).to receive(:broadcast)
    channel.update!(provider_config: channel.provider_config.merge(
      'unanswered_calls_enabled' => true, 'unanswered_call_timeout_seconds' => 30, 'unanswered_call_message' => 'Nobody is available right now.'
    ))
    call.update!(message: Voice::CallMessageBuilder.new(call).perform!)
  end

  it 'moves the caller to the announcement, hangs up, and records the missed call' do
    expect(service.perform).to be_nil

    expect(twilio_client).to have_received(:calls).with(call.provider_call_id)
    xml = Nokogiri::XML(sent_twiml.sole)
    expect(xml.at_xpath('/Response/Say').text).to eq('Nobody is available right now.')
    expect(xml.at_xpath('/Response/Hangup')).to be_present
    expect(call.reload).to have_attributes(status: 'no_answer', end_reason: 'ring_timeout')
    expect(call.ended_at).to be_present
  end

  it 'updates the call message and tells the dashboards the call ended' do
    service.perform

    expect(call.message.reload.content_attributes.dig('data', 'status')).to eq('no-answer')
    expect(ActionCable.server).to have_received(:broadcast).with("account_#{account.id}", hash_including(event: 'voice_call.ended'))
  end

  it 'plays the generated announcement audio when there is one' do
    inbox.unanswered_call_audio.attach(io: StringIO.new('audio'), filename: 'unanswered.mp3', content_type: 'audio/mpeg')

    service.perform

    play = Nokogiri::XML(sent_twiml.sole).at_xpath('/Response/Play')
    expect(play.text).to start_with('http://localhost:3000/rails/active_storage/').and end_with('/unanswered.mp3')
  end

  it 'gives an agent connection on its way in its time to join before deciding' do
    call.with_lock { call.record_agent_leg!(Call.pending_agent_leg('attempt-1'), 'joining') }

    expect(service.perform).to be_between(1, Call::AGENT_LEG_JOIN_GRACE_SECONDS)
    expect(sent_twiml).to be_empty
    expect(call.reload).to be_ringing
    expect(call.ring_state).not_to have_key('timing_out_at')
  end

  it 'leaves a call answered meanwhile alone' do
    call.update!(status: 'in_progress')

    expect(service.perform).to be_nil
    expect(sent_twiml).to be_empty
    expect(call.reload).to be_in_progress
  end

  it 'keeps a call Twilio shows an agent on, whose join was never reported' do
    allow(conference).to receive(:agents_remain?).and_return(true)

    expect(service.perform).to be_nil
    expect(sent_twiml).to be_empty
    expect(call.reload).to be_ringing
    expect(call.ring_state).not_to have_key('timing_out_at')
  end

  it 'records the missed call when the caller hung up just before' do
    allow(twilio_call).to receive(:update)
      .and_raise(Twilio::REST::RestError.new('Call is not in-progress', Twilio::Response.new(400, { 'code' => 21_220 }.to_json)))

    expect(service.perform).to be_nil
    expect(call.reload).to have_attributes(status: 'no_answer', end_reason: 'ring_timeout')
  end

  it 'clears its mark and raises when Twilio cannot be reached, so the call can still be answered' do
    allow(twilio_call).to receive(:update).and_raise(Twilio::REST::RestError.new('down', Twilio::Response.new(503, '{}')))

    expect { service.perform }.to raise_error(Twilio::REST::RestError)
    expect(call.reload).to be_ringing
    expect(call.ring_state).not_to have_key('timing_out_at')
  end

  it 'does not start while another attempt is ending the call' do
    call.update!(ring_state: { 'timing_out_at' => Time.zone.now.to_i })

    expect(service.perform).to be_nil
    expect(sent_twiml).to be_empty
    expect(call.reload).to be_ringing
  end
end
