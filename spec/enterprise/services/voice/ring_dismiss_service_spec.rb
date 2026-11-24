require 'rails_helper'

describe Voice::RingDismissService do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account) }
  let(:teammate) { create(:user, account: account) }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(16)}"))
  end

  shared_examples 'a ring an agent can dismiss' do
    let(:conversation) { create(:conversation, account: account, inbox: inbox) }
    let(:message) { create(:message, account: account, inbox: inbox, conversation: conversation, content_type: 'voice_call') }
    let(:call) do
      create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact, provider: provider,
                    message: message, ring_state: { 'ring_recipient_ids' => [agent.id, teammate.id] })
    end

    def dismiss(user) = described_class.new(call: call, user: user).perform

    it 'stops the ring for the agent only and names who still rings on the message' do
      dismiss(agent)

      expect(call.reload).to be_ringing
      expect(call.dismissed_user_ids).to eq([agent.id])
      expect(message.reload.content_attributes['data']).to include('ring_user_ids' => [teammate.id], 'dismissed_user_ids' => [agent.id])
    end

    it 'moves the ring on to its next step at once' do
      expect { dismiss(agent) }.to have_enqueued_job(Voice::RingNextAgentJob).with(call.id, 2)
    end

    it 'keeps the agent in the ring when the next step cannot be queued, so the dismiss can be retried' do
      allow(Voice::RingNextAgentJob).to receive(:perform_later).and_raise(RedisClient::CannotConnectError)

      expect { dismiss(agent) }.to raise_error(RedisClient::CannotConnectError)
      expect(call.reload).to have_attributes(dismissed_user_ids: [], ring_step: 1)
    end

    it 'changes nothing for an agent the call does not ring, or a repeated dismiss' do
      outsider = create(:user, account: account)
      dismiss(agent)

      expect { dismiss(agent) }.not_to have_enqueued_job(Voice::RingNextAgentJob)
      expect { dismiss(outsider) }.not_to have_enqueued_job(Voice::RingNextAgentJob)
      expect(call.reload).to have_attributes(dismissed_user_ids: [agent.id], ring_step: 2)
    end

    it 'leaves a call that is no longer ringing alone' do
      call.update!(status: 'in_progress')

      expect { dismiss(agent) }.not_to have_enqueued_job(Voice::RingNextAgentJob)
      expect(call.reload.dismissed_user_ids).to be_empty
    end
  end

  context 'with a Twilio call' do
    let(:inbox) { create(:channel_twilio_sms, :with_voice, account: account).inbox }
    let(:provider) { :twilio }

    it_behaves_like 'a ring an agent can dismiss'
  end

  context 'with a WhatsApp call' do
    let(:inbox) { create(:channel_whatsapp, account: account, sync_templates: false, validate_provider_config: false).inbox }
    let(:provider) { :whatsapp }

    it_behaves_like 'a ring an agent can dismiss'
  end
end
