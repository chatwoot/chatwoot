require 'rails_helper'

describe Whatsapp::CallService do
  let(:account) { create(:account) }
  let(:channel) do
    create(:channel_whatsapp, provider: 'whatsapp_cloud', account: account,
                              validate_provider_config: false, sync_templates: false)
  end
  let(:inbox) { channel.inbox }
  let(:agent) { create(:user, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:call) do
    create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact,
                  provider: :whatsapp, direction: :incoming, status: 'ringing', provider_call_id: 'wacid_abc')
  end
  let(:provider_service) { instance_double(Whatsapp::Providers::WhatsappCloudService) }

  before do
    channel.provider_config = channel.provider_config.merge('calling_enabled' => true)
    channel.save!
    allow(channel).to receive(:provider_service).and_return(provider_service)
    allow(inbox).to receive(:channel).and_return(channel)
    allow(call).to receive(:inbox).and_return(inbox)
    allow(ActionCable.server).to receive(:broadcast)
  end

  describe '#accept' do
    let(:sdp_answer) { "v=0\r\n...sdp..." }

    before do
      allow(provider_service).to receive(:pre_accept_call).and_return(true)
      allow(provider_service).to receive(:accept_call).and_return(true)
    end

    it 'forwards the SDP answer to Meta and transitions the call to in_progress' do
      described_class.new(call: call, agent: agent, sdp_answer: sdp_answer).accept

      expect(provider_service).to have_received(:pre_accept_call).with('wacid_abc', sdp_answer)
      expect(provider_service).to have_received(:accept_call).with('wacid_abc', sdp_answer)
      expect(call.reload).to have_attributes(status: 'in_progress', accepted_by_agent_id: agent.id, started_at: be_present)
      expect(call.meta['sdp_answer']).to eq(sdp_answer)
      expect(ActionCable.server).to have_received(:broadcast).with(
        "account_#{account.id}", hash_including(event: 'voice_call.accepted')
      )
    end

    it 'claims the conversation when no assignee is set' do
      described_class.new(call: call, agent: agent, sdp_answer: sdp_answer).accept

      expect(conversation.reload.assignee_id).to eq(agent.id)
    end

    it 'raises AlreadyAccepted when another agent has already accepted the call' do
      call.update!(status: 'in_progress')

      expect { described_class.new(call: call, agent: agent, sdp_answer: sdp_answer).accept }
        .to raise_error(StandardError) { |error| expect(error.class.name).to eq('Voice::CallErrors::AlreadyAccepted') }
    end

    it 'raises NotRinging when the call has reached a terminal state' do
      call.update!(status: 'completed')

      expect { described_class.new(call: call, agent: agent, sdp_answer: sdp_answer).accept }
        .to raise_error(StandardError) { |error| expect(error.class.name).to eq('Voice::CallErrors::NotRinging') }
    end

    it 'raises CallFailed when sdp_answer is missing' do
      expect { described_class.new(call: call, agent: agent, sdp_answer: nil).accept }
        .to raise_error(StandardError) do |error|
          expect(error.class.name).to eq('Voice::CallErrors::CallFailed')
          expect(error.message).to eq('sdp_answer is required')
        end
    end

    it 'wraps Meta transport exceptions as CallFailed and leaves the call ringing' do
      allow(provider_service).to receive(:pre_accept_call).and_raise(Faraday::TimeoutError)

      expect { described_class.new(call: call, agent: agent, sdp_answer: sdp_answer).accept }
        .to raise_error(StandardError) { |error| expect(error.class.name).to eq('Voice::CallErrors::CallFailed') }
      expect(call.reload.status).to eq('ringing')
    end
  end

  describe '#reject' do
    before { allow(provider_service).to receive(:reject_call).and_return(true) }

    it 'tells Meta to reject and finalizes the call as failed' do
      described_class.new(call: call, agent: agent).reject

      expect(provider_service).to have_received(:reject_call).with('wacid_abc')
      expect(call.reload.status).to eq('failed')
      expect(ActionCable.server).to have_received(:broadcast).with(
        "account_#{account.id}", hash_including(event: 'voice_call.ended', data: hash_including(status: 'failed'))
      )
    end

    it 'is a no-op for already-terminal calls' do
      call.update!(status: 'completed')

      described_class.new(call: call, agent: agent).reject

      expect(provider_service).not_to have_received(:reject_call)
    end

    it 'raises CallFailed and leaves the call ringing when Meta rejects the request' do
      allow(provider_service).to receive(:reject_call).and_return(false)

      expect { described_class.new(call: call, agent: agent).reject }
        .to raise_error(StandardError) { |error| expect(error.class.name).to eq('Voice::CallErrors::CallFailed') }
      expect(call.reload.status).to eq('ringing')
    end
  end

  describe '#terminate' do
    before { allow(provider_service).to receive(:terminate_call).and_return(true) }

    it 'finalizes an in-progress call as completed' do
      call.update!(status: 'in_progress')

      described_class.new(call: call, agent: agent).terminate

      expect(provider_service).to have_received(:terminate_call).with('wacid_abc')
      expect(call.reload.status).to eq('completed')
      expect(call.meta['ended_at']).to be_present
      expect(ActionCable.server).to have_received(:broadcast).with(
        "account_#{account.id}", hash_including(event: 'voice_call.ended')
      )
    end

    it 'finalizes a still-ringing call as no_answer when the agent hangs up before the contact picks up' do
      described_class.new(call: call, agent: agent).terminate

      expect(call.reload.status).to eq('no_answer')
    end
  end
end
