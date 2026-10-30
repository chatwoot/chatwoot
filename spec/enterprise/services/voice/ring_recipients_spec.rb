require 'rails_helper'

RSpec.describe Voice::RingRecipients do
  subject(:recipients) { described_class.new(inbox: inbox, conversation: conversation, dismissed_user_ids: dismissed) }

  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account) }
  let(:inbox) { channel.inbox }
  let(:alice) { create(:user, account: account, role: :agent) }
  let(:bob) { create(:user, account: account, role: :agent) }
  let(:cara) { create(:user, account: account, role: :agent) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:other_conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:dismissed) { [] }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(8)}"))
    [alice, bob, cara].each { |user| create(:inbox_member, user: user, inbox: inbox) }
  end

  it 'rings every online agent who can open the conversation, leaving out the offline and the dismissed' do
    AccountUser.find_by(user: cara, account: account).update!(availability: :offline)

    expect(described_class.new(inbox: inbox, conversation: conversation, dismissed_user_ids: [bob.id]).agents).to eq([alice])
  end

  it 'rings a free assignee alone' do
    conversation.update!(assignee: alice)

    expect(recipients.agents).to eq([alice])
  end

  it 'rings the teammates when the assignee is busy' do
    conversation.update!(assignee: alice)
    AccountUser.find_by(user: alice, account: account).update!(availability: :busy)

    expect(recipients.agents).to contain_exactly(bob, cara)
  end

  it 'rings the whole team, not the assignee alone, when the assignee is on another call' do
    conversation.update!(assignee: alice)
    create(:call, account: account, inbox: inbox, conversation: other_conversation, contact: other_conversation.contact,
                  status: 'in_progress', accepted_by_agent: alice)

    expect(recipients.agents).to contain_exactly(alice, bob, cara)
  end

  context 'when the inbox prefers free agents' do
    before do
      channel.update!(provider_config: channel.provider_config.merge('prefer_free_agents' => true))
      create(:call, account: account, inbox: inbox, conversation: other_conversation, contact: other_conversation.contact,
                    status: 'in_progress', accepted_by_agent: bob)
    end

    it 'rings only the agents not on a call' do
      expect(recipients.agents).to contain_exactly(alice, cara)
    end

    it 'rings everyone when every agent is on a call' do
      [alice, cara].each do |agent|
        busy = create(:conversation, account: account, inbox: inbox)
        create(:call, account: account, inbox: inbox, conversation: busy, contact: busy.contact, status: 'in_progress', accepted_by_agent: agent)
      end

      expect(recipients.agents).to contain_exactly(alice, bob, cara)
    end
  end

  context 'when the inbox rings in turn' do
    before do
      channel.update!(provider_config: channel.provider_config.merge('ring_strategy' => 'sequential', 'call_cooldown_seconds' => 60))
      [[alice, 3600], [bob, 600]].each do |agent, ended_ago|
        done = create(:conversation, account: account, inbox: inbox)
        create(:call, account: account, inbox: inbox, conversation: done, contact: done.contact, status: 'completed',
                      accepted_by_agent: agent, started_at: (ended_ago + 60).seconds.ago, meta: { 'ended_at' => ended_ago.seconds.ago.to_i })
      end
    end

    it 'starts with the longest idle agent, one who never answered a call ranking first' do
      expect(recipients.agents).to eq([cara])
      expect(recipients.next_agent([cara.id])).to eq(alice)
      expect(recipients.next_agent([cara.id, alice.id])).to eq(bob)
    end

    it 'rings an agent in cooldown after the others, and one who resolved that call by idle time' do
      [[cara, 40, :open], [bob, 30, :resolved]].each do |agent, ended_ago, status|
        recent = create(:conversation, account: account, inbox: inbox, status: status)
        create(:call, account: account, inbox: inbox, conversation: recent, contact: recent.contact, status: 'completed',
                      accepted_by_agent: agent, started_at: 2.minutes.ago, meta: { 'ended_at' => ended_ago.seconds.ago.to_i })
      end

      expect(recipients.agents).to eq([alice])
      expect(recipients.next_agent([alice.id])).to eq(bob)
      expect(recipients.next_agent([alice.id, bob.id])).to eq(cara)
    end

    it 'starts with the assignee even in cooldown' do
      conversation.update!(assignee: bob)
      cooling = create(:conversation, account: account, inbox: inbox)
      create(:call, account: account, inbox: inbox, conversation: cooling, contact: cooling.contact, status: 'completed',
                    accepted_by_agent: bob, started_at: 2.minutes.ago, meta: { 'ended_at' => 20.seconds.ago.to_i })

      expect(recipients.agents).to eq([bob])
    end
  end

  context 'with a WhatsApp inbox' do
    let(:inbox) { create(:channel_whatsapp, account: account, sync_templates: false, validate_provider_config: false).inbox }

    it 'keeps ringing an assignable assignee alone, even when they are busy' do
      conversation.update!(assignee: alice)
      AccountUser.find_by(user: alice, account: account).update!(availability: :busy)

      expect(recipients.agents).to be_empty
    end
  end
end
