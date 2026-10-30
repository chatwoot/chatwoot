# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voice::RingingTimeoutService do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account, phone_number: '+15551239999') }
  let(:inbox) { channel.inbox }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:call) { create(:call, conversation: conversation, provider: :whatsapp, status: 'ringing') }
  let(:conference) { instance_double(Voice::Provider::Twilio::ConferenceService, terminate_call: nil) }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(8)}"))
    account.enable_features!('mobile_voice_push')
    allow(Voice::Provider::Twilio::ConferenceService).to receive(:new).and_return(conference)
    allow(ActionCable.server).to receive(:broadcast)
    call.update!(message: Voice::CallMessageBuilder.new(call).perform!)
  end

  describe '.overdue' do
    def ringing(provider, age)
      create(:call, conversation: create(:conversation, account: account, inbox: inbox), provider: provider, status: 'ringing',
                    created_at: age.ago, ring_state: { 'ring_recipient_ids' => [] })
    end

    it 'ignores a call that rang no phones, with no agents recorded for it' do
      ringing(:whatsapp, 5.minutes).update!(ring_state: {})

      expect(described_class.overdue).to be_empty
    end

    it 'returns WhatsApp calls ringing for more than 60 s, and leaves Twilio callers waiting' do
      overdue_whatsapp = ringing(:whatsapp, 61.seconds)
      ringing(:twilio, 5.minutes)
      ringing(:whatsapp, 59.seconds)

      expect(described_class.overdue).to contain_exactly(overdue_whatsapp)
    end

    it 'ignores calls that are no longer ringing' do
      old = ringing(:whatsapp, 5.minutes)
      old.update!(status: 'in_progress')

      expect(described_class.overdue).to be_empty
    end

    it 'ignores outbound calls, which end with the provider' do
      ringing(:whatsapp, 5.minutes).update!(direction: :outgoing)

      expect(described_class.overdue).to be_empty
    end

    it 'still returns a call that rang phones after the account stopped ringing them' do
      overdue = ringing(:whatsapp, 5.minutes)
      account.disable_features!('mobile_voice_push')

      expect(described_class.overdue).to contain_exactly(overdue)
    end
  end

  describe '#perform' do
    before { call.update!(created_at: 61.seconds.ago) }

    it 'ends the call as missed' do
      described_class.new(call: call).perform

      call.reload
      expect(call.status).to eq('no_answer')
      expect(call.end_reason).to eq('ring_timeout')
      expect(call.meta['ended_at']).to be_present
    end

    it 'updates the call message and the conversation the way a provider hang-up does' do
      described_class.new(call: call).perform

      expect(call.reload.message.content_attributes.dig('data', 'status')).to eq('no-answer')
      expect(conversation.reload.additional_attributes['call_status']).to eq('no-answer')
    end

    it 'broadcasts voice_call.ended to the account' do
      described_class.new(call: call).perform

      expect(ActionCable.server).to have_received(:broadcast).with(
        "account_#{account.id}", hash_including(event: 'voice_call.ended', data: hash_including(id: call.id, status: 'no-answer'))
      )
    end

    it 'does not end a call answered before the sweep reached it' do
      call.update!(status: 'in_progress', accepted_by_agent: create(:user, account: account))

      described_class.new(call: call).perform

      expect(call.reload.status).to eq('in_progress')
      expect(ActionCable.server).not_to have_received(:broadcast)
    end

    it 'leaves a call alone while another sweep is hanging it up, and waits out its mark' do
      call.update!(ring_state: { 'timing_out_at' => 10.seconds.ago.to_i })

      expect(described_class.new(call: call).perform).to be_within(1).of(110)

      expect(call.reload.status).to eq('ringing')
      expect(ActionCable.server).not_to have_received(:broadcast)
    end

    it 'takes over from a sweep that died long ago' do
      call.update!(ring_state: { 'timing_out_at' => 5.minutes.ago.to_i })

      described_class.new(call: call).perform

      expect(call.reload.status).to eq('no_answer')
    end

    it 'leaves a Twilio caller waiting on hold when the inbox does not end unanswered calls' do
      call.update!(provider: :twilio, created_at: 5.minutes.ago)

      described_class.new(call: call).perform

      expect(call.reload.status).to eq('ringing')
      expect(conference).not_to have_received(:terminate_call)
    end

    it 'does not touch a call that was answered in the meantime' do
      call.update!(status: 'in_progress')

      described_class.new(call: call).perform

      expect(call.reload.status).to eq('in_progress')
      expect(ActionCable.server).not_to have_received(:broadcast)
    end

    it 'leaves a late provider end-of-ring with nothing to change' do
      described_class.new(call: call).perform
      described_class.new(call: call).perform

      expect(call.reload.status).to eq('no_answer')
      expect(ActionCable.server).to have_received(:broadcast).once
    end
  end

  describe '#perform for a Twilio call past the inbox ring time' do
    let(:call) { create(:call, conversation: conversation, status: 'ringing') }
    let(:conference) { instance_double(Voice::Provider::Twilio::ConferenceService, agents_remain?: false) }
    let(:twilio_call) { instance_double(Twilio::REST::Api::V2010::AccountContext::CallContext) }
    let(:twilio_client) { instance_double(Twilio::REST::Client, calls: twilio_call) }
    let(:sent_twiml) { [] }
    let(:service) { described_class.new(call: call) }

    before do
      allow(Twilio::REST::Client).to receive(:new).and_return(twilio_client)
      allow(twilio_call).to receive(:update) { |twiml:| sent_twiml << twiml }
      channel.update!(provider_config: channel.provider_config.merge(
        'unanswered_calls_enabled' => true, 'unanswered_call_timeout_seconds' => 30, 'unanswered_call_message' => 'Nobody is available right now.'
      ))
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

    it "records the ring time's outcome when the move's own webhooks end the call first" do
      allow(twilio_call).to receive(:update) do
        Voice::CallStatus::Manager.new(call: Call.find(call.id)).process_status_update('completed', timestamp: Time.zone.now.to_i)
      end

      expect(service.perform).to be_nil

      expect(call.reload).to have_attributes(status: 'no_answer', end_reason: 'ring_timeout')
      expect(call.message.reload.content_attributes.dig('data', 'status')).to eq('no-answer')
    end

    it 'records the missed call when a claim whose leg never joined is ended by the move' do
      call.update!(accepted_by_agent: create(:user, account: account))
      allow(twilio_call).to receive(:update) do
        Voice::CallStatus::Manager.new(call: Call.find(call.id)).process_status_update('completed', timestamp: Time.zone.now.to_i)
      end

      service.perform

      expect(call.reload).to have_attributes(status: 'no_answer', end_reason: 'ring_timeout')
    end

    it 'updates the call message and tells the dashboards the call ended' do
      service.perform

      expect(call.message.reload.content_attributes.dig('data', 'status')).to eq('no-answer')
      expect(ActionCable.server).to have_received(:broadcast).with("account_#{account.id}", hash_including(event: 'voice_call.ended'))
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

    it 'keeps its mark when recording the missed call fails after the caller was moved, so no agent joins an empty call' do
      allow(call).to receive(:broadcast_voice_call_event).and_raise(ActiveRecord::StatementInvalid)

      expect { service.perform }.to raise_error(ActiveRecord::StatementInvalid)
      expect(sent_twiml).to be_present
      expect(call.reload.ring_state).to have_key('timing_out_at')
      expect(call).to be_ring_timeout_in_progress
    end

    it 'leaves the caller waiting when the inbox does not end unanswered calls' do
      channel.update!(provider_config: channel.provider_config.merge('unanswered_calls_enabled' => false))

      expect(service.perform).to be_nil
      expect(sent_twiml).to be_empty
      expect(call.reload).to be_ringing
    end
  end
end
