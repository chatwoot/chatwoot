require 'rails_helper'

describe Whatsapp::IncomingCallService do
  let(:account) { create(:account) }
  let(:channel) do
    create(:channel_whatsapp, provider: 'whatsapp_cloud', account: account,
                              validate_provider_config: false, sync_templates: false)
  end
  let(:inbox) { channel.inbox }
  let(:from_number) { '15550001111' }
  let(:provider_call_id) { 'wacid_abc' }

  before do
    account.enable_features!('channel_voice')
    channel.provider_config = channel.provider_config.merge('source' => 'embedded_signup', 'calling_enabled' => true)
    channel.save!
  end

  def call_payload(event:, **extra)
    { calls: [{ id: provider_call_id, from: from_number, event: event, **extra }] }
  end

  context 'when calling is disabled on the channel' do
    it 'is a no-op' do
      channel.provider_config = channel.provider_config.merge('calling_enabled' => false)
      channel.save!

      expect { described_class.new(inbox: inbox, params: call_payload(event: 'connect')).perform }
        .not_to change(Call, :count)
    end
  end

  describe 'inbound connect' do
    let(:sdp_offer) { "v=0\r\n...sdp..." }

    it 'creates the Call + Conversation + voice_call message and broadcasts voice_call.incoming' do
      allow(ActionCable.server).to receive(:broadcast)

      params = call_payload(event: 'connect', session: { sdp: sdp_offer, sdp_type: 'offer' })
      expect { described_class.new(inbox: inbox, params: params).perform }
        .to change(Call, :count).by(1).and change(Conversation, :count).by(1)

      call = Call.last
      expect(call).to have_attributes(provider: 'whatsapp', direction: 'incoming', status: 'ringing',
                                      provider_call_id: provider_call_id)
      expect(call.meta['sdp_offer']).to eq(sdp_offer)
      expect(ActionCable.server).to have_received(:broadcast).with(
        "account_#{account.id}",
        hash_including(event: 'voice_call.incoming', data: hash_including(sdp_offer: sdp_offer))
      )
    end
  end

  describe 'outbound connect (existing call)' do
    let!(:call) do
      conversation = create(:conversation, account: account, inbox: inbox)
      create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact,
                    provider: :whatsapp, direction: :outgoing, status: 'ringing', provider_call_id: provider_call_id)
    end

    it 'stores the SDP answer and broadcasts voice_call.outbound_connected without flipping to in_progress' do
      allow(ActionCable.server).to receive(:broadcast)
      sdp_answer = "v=0\r\na=setup:actpass\r\n"

      params = call_payload(event: 'connect', session: { sdp: sdp_answer, sdp_type: 'answer' })
      described_class.new(inbox: inbox, params: params).perform

      # connect only completes the SDP handshake; pickup is reported separately as status=ACCEPTED.
      expect(call.reload).to have_attributes(status: 'ringing', started_at: nil)
      expect(call.meta['sdp_answer']).to include('a=setup:active')
      expect(ActionCable.server).to have_received(:broadcast).with(
        "account_#{account.id}",
        hash_including(event: 'voice_call.outbound_connected')
      )
    end
  end

  describe 'terminate' do
    let!(:call) do
      conversation = create(:conversation, account: account, inbox: inbox)
      create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact,
                    provider: :whatsapp, direction: :incoming, status: 'in_progress', provider_call_id: provider_call_id)
    end

    it 'marks the call completed when the call had been answered' do
      allow(ActionCable.server).to receive(:broadcast)

      params = call_payload(event: 'terminate', duration: 42, terminate_reason: 'completed_normally')
      described_class.new(inbox: inbox, params: params).perform

      expect(call.reload).to have_attributes(status: 'completed', duration_seconds: 42, end_reason: 'completed_normally')
      expect(call.ended_at).to be_present
      expect(ActionCable.server).to have_received(:broadcast).with(
        "account_#{account.id}",
        hash_including(event: 'voice_call.ended', data: hash_including(status: 'completed'))
      )
    end

    it 'marks unanswered ringing calls as no_answer' do
      call.update!(status: 'ringing')
      params = call_payload(event: 'terminate', duration: 0, terminate_reason: 'no_answer')

      described_class.new(inbox: inbox, params: params).perform
      expect(call.reload.status).to eq('no_answer')
    end

    it 'records the call as failed when Meta reports a failure reason for an in_progress call' do
      allow(ActionCable.server).to receive(:broadcast)

      params = call_payload(event: 'terminate', duration: 12, terminate_reason: 'failed')
      described_class.new(inbox: inbox, params: params).perform

      expect(call.reload).to have_attributes(status: 'failed', duration_seconds: 12, end_reason: 'failed')
    end

    it 'is a no-op when the call is already terminal so retries cannot flip a completed call to no_answer' do
      call.update!(status: 'completed', duration_seconds: 5, direction: :outgoing, accepted_by_agent: nil)
      allow(ActionCable.server).to receive(:broadcast)
      params = call_payload(event: 'terminate', duration: 0, terminate_reason: 'completed_normally')

      described_class.new(inbox: inbox, params: params).perform

      expect(call.reload).to have_attributes(status: 'completed', duration_seconds: 5)
      expect(ActionCable.server).not_to have_received(:broadcast)
    end
  end

  describe 'terminate with no local row yet' do
    it 'logs and skips instead of materialising an inbound missed-call row' do
      allow(Rails.logger).to receive(:warn)
      allow(ActionCable.server).to receive(:broadcast)

      params = call_payload(event: 'terminate', duration: 0, terminate_reason: 'no_answer')

      expect { described_class.new(inbox: inbox, params: params).perform }
        .not_to change(Call, :count)
      expect(Rails.logger).to have_received(:warn).with(/Terminate for unknown call/)
      expect(ActionCable.server).not_to have_received(:broadcast)
    end
  end

  describe 'outbound connect with no local row yet' do
    it 'does not mint an inbound call when sdp_type is answer' do
      allow(Rails.logger).to receive(:warn)
      allow(ActionCable.server).to receive(:broadcast)

      params = call_payload(event: 'connect', session: { sdp: 'sdp_answer', sdp_type: 'answer' })

      expect { described_class.new(inbox: inbox, params: params).perform }
        .not_to change(Call, :count)
      expect(Rails.logger).to have_received(:warn).with(/Outbound connect for unknown call/)
      expect(ActionCable.server).not_to have_received(:broadcast)
    end
  end

  describe 'duplicate inbound connect' do
    let!(:call) do
      conversation = create(:conversation, account: account, inbox: inbox)
      create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact,
                    provider: :whatsapp, direction: :incoming, status: 'ringing', provider_call_id: provider_call_id)
    end

    it 'logs and ignores rather than treating it as outbound' do
      allow(Rails.logger).to receive(:info)
      allow(ActionCable.server).to receive(:broadcast)
      params = call_payload(event: 'connect', session: { sdp: 'sdp_x', sdp_type: 'offer' })

      described_class.new(inbox: inbox, params: params).perform

      expect(call.reload).to have_attributes(status: 'ringing')
      expect(Rails.logger).to have_received(:info).with(/Duplicate inbound connect/)
      expect(ActionCable.server).not_to have_received(:broadcast)
    end
  end

  describe 'connect arriving after terminal status' do
    let!(:call) do
      conversation = create(:conversation, account: account, inbox: inbox)
      create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact,
                    provider: :whatsapp, direction: :outgoing, status: 'completed', provider_call_id: provider_call_id)
    end

    it 'does not reopen a completed outbound call' do
      allow(ActionCable.server).to receive(:broadcast)
      params = call_payload(event: 'connect', session: { sdp: 'late_sdp', sdp_type: 'answer' })

      described_class.new(inbox: inbox, params: params).perform

      expect(call.reload.status).to eq('completed')
      expect(ActionCable.server).not_to have_received(:broadcast)
    end
  end

  describe 'unanswered outbound call terminate' do
    let!(:agent) { create(:user, account: account) }
    let!(:call) do
      conversation = create(:conversation, account: account, inbox: inbox)
      create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact,
                    provider: :whatsapp, direction: :outgoing, status: 'ringing',
                    accepted_by_agent: agent, provider_call_id: provider_call_id)
    end

    it 'marks the call as no_answer even though accepted_by_agent_id is set' do
      allow(ActionCable.server).to receive(:broadcast)
      params = call_payload(event: 'terminate', duration: 0, terminate_reason: 'no_answer')

      described_class.new(inbox: inbox, params: params).perform

      expect(call.reload.status).to eq('no_answer')
      expect(ActionCable.server).to have_received(:broadcast).with(
        "account_#{account.id}",
        hash_including(event: 'voice_call.ended', data: hash_including(status: 'no-answer'))
      )
    end
  end

  describe 'unknown event' do
    it 'logs a warning and does not raise' do
      allow(Rails.logger).to receive(:warn)
      params = call_payload(event: 'mystery')

      expect { described_class.new(inbox: inbox, params: params).perform }.not_to raise_error
      expect(Rails.logger).to have_received(:warn).with(/Unknown call event: mystery/)
    end
  end

  describe 'multiple calls in one webhook payload' do
    it 'processes every call in the array' do
      allow(ActionCable.server).to receive(:broadcast)

      params = {
        calls: [
          { id: 'wacid_a', from: from_number, event: 'connect', session: { sdp: 'sdp_a', sdp_type: 'offer' } },
          { id: 'wacid_b', from: '15550002222', event: 'connect', session: { sdp: 'sdp_b', sdp_type: 'offer' } }
        ]
      }

      expect { described_class.new(inbox: inbox, params: params).perform }.to change(Call, :count).by(2)
      expect(Call.where(provider_call_id: %w[wacid_a wacid_b]).pluck(:provider_call_id)).to contain_exactly('wacid_a', 'wacid_b')
    end
  end
end
