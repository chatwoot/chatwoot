require 'rails_helper'

RSpec.describe Voice::RingNextAgentJob do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account) }
  let(:inbox) { channel.inbox }
  let(:alice) { create(:user, account: account, role: :agent) }
  let(:bob) { create(:user, account: account, role: :agent) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:message) { create(:message, account: account, inbox: inbox, conversation: conversation, content_type: 'voice_call') }
  let(:call) do
    create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact, message: message,
                  ring_state: { 'ring_recipient_ids' => [alice.id], 'rings_phones' => false })
  end

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(8)}"))
    channel.update!(provider_config: channel.provider_config.merge('ring_strategy' => 'sequential', 'ring_step_seconds' => 15))
    [alice, bob].each { |user| create(:inbox_member, user: user, inbox: inbox) }
  end

  it 'adds the next agent, names the agents rung on the message and queues the next step' do
    expect { described_class.perform_now(call.id, 1) }
      .to have_enqueued_job(described_class).with(call.id, 2).at(a_value_within(2.seconds).of(15.seconds.from_now))

    expect(call.reload.ring_state).to include('ring_recipient_ids' => [alice.id, bob.id], 'ring_step' => 2)
    expect(message.reload.content_attributes.dig('data', 'ring_user_ids')).to eq([alice.id, bob.id])
  end

  it 'keeps stepping once everyone rings, so an agent who comes online later is reached' do
    call.update!(ring_state: call.ring_state.merge('ring_recipient_ids' => [alice.id, bob.id]))

    expect { described_class.perform_now(call.id, 1) }.to have_enqueued_job(described_class).with(call.id, 2)
    expect(call.reload.ring_state['ring_recipient_ids']).to eq([alice.id, bob.id])
  end

  it 'does nothing for a step a dismiss moved past' do
    call.update!(ring_state: call.ring_state.merge('ring_step' => 3))

    expect { described_class.perform_now(call.id, 1) }.not_to have_enqueued_job(described_class)
    expect(call.reload.ring_state['ring_recipient_ids']).to eq([alice.id])
  end

  it 'adds nobody while an agent picks the call up, and keeps stepping in case their connection fails' do
    call.update!(accepted_by_agent: alice)

    expect { described_class.perform_now(call.id, 1) }.to have_enqueued_job(described_class).with(call.id, 2)
    expect(call.reload.ring_state).to include('ring_recipient_ids' => [alice.id], 'ring_step' => 2)
  end

  it 'reaches an agent who comes online after the call found nobody to ring' do
    call.update!(ring_state: call.ring_state.merge('ring_recipient_ids' => []))
    [alice, bob].each { |user| AccountUser.find_by(user: user, account: account).update!(availability: :offline) }
    expect { described_class.perform_now(call.id, 1) }.to have_enqueued_job(described_class).with(call.id, 2)
    expect(call.reload.ring_state['ring_recipient_ids']).to eq([])

    AccountUser.find_by(user: bob, account: account).update!(availability: :online)
    described_class.perform_now(call.id, 2)
    expect(call.reload.ring_state['ring_recipient_ids']).to eq([bob.id])
  end

  it 'stops once the call is answered' do
    call.update!(status: 'in_progress')

    expect { described_class.perform_now(call.id, 1) }.not_to have_enqueued_job(described_class)
  end

  it 'stops stepping once the call has rung for the longest ring time an inbox can set' do
    call.update!(created_at: (described_class::MAX_RING_SECONDS + 1).seconds.ago)

    expect { described_class.perform_now(call.id, 1) }.not_to have_enqueued_job(described_class)
    expect(call.reload.ring_state['ring_recipient_ids']).to eq([alice.id, bob.id])
  end

  context 'when the inbox rings everyone at once' do
    before { channel.update!(provider_config: channel.provider_config.merge('ring_strategy' => 'simultaneous')) }

    it 'adds the agents who became available since and queues the next step' do
      expect { described_class.perform_now(call.id, 1) }.to have_enqueued_job(described_class).with(call.id, 2)
      expect(message.reload.content_attributes.dig('data', 'ring_user_ids')).to eq([alice.id, bob.id])
    end

    it 'rings the team after the first step of an assignee ringing alone' do
      conversation.update!(assignee: alice)

      described_class.perform_now(call.id, 1)

      expect(call.reload.ring_state['ring_recipient_ids']).to eq([alice.id, bob.id])
    end

    it 'rings the team once the assignee it rang alone dismissed it' do
      conversation.update!(assignee: alice)
      call.update!(ring_state: call.ring_state.merge('dismissed_user_ids' => [alice.id]))

      described_class.perform_now(call.id, 1)

      expect(message.reload.content_attributes.dig('data', 'ring_user_ids')).to eq([bob.id])
    end
  end

  it "rings the added agent's phones only when the call rings phones" do
    push = instance_double(Voice::AddedRingPushService, perform: nil)
    allow(Voice::AddedRingPushService).to receive(:new).and_return(push)

    described_class.perform_now(call.id, 1)
    expect(Voice::AddedRingPushService).not_to have_received(:new)

    call.reload.update!(ring_state: call.ring_state.merge('rings_phones' => true, 'ring_recipient_ids' => [alice.id]))
    described_class.perform_now(call.id, 2)
    expect(Voice::AddedRingPushService).to have_received(:new).with(call: an_instance_of(Call), users: [bob])
  end
end
