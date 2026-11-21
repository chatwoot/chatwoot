require 'rails_helper'

# Sales rings only its assignee, customer service rings only its members, and mike is in no team.
# The conversation's team is set before its assignee, since changing the team clears an assignee
# outside it.
RSpec.describe Voice::RingRecipients do
  subject(:recipients) { ring }

  let(:account) { create(:account) }
  let(:inbox) { create(:channel_twilio_sms, :with_voice, account: account).inbox }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:sales) { create(:team, account: account, name: 'sales', allow_auto_assign: false, widen_calls: :assignee_only) }
  let(:service) { create(:team, account: account, name: 'customer service', allow_auto_assign: false, widen_calls: :team_members) }
  let(:sam) { create(:user, account: account, role: :agent) }
  let(:sid) { create(:user, account: account, role: :agent) }
  let(:sue) { create(:user, account: account, role: :agent) }
  let(:cass) { create(:user, account: account, role: :agent) }
  let(:cole) { create(:user, account: account, role: :agent) }
  let(:cora) { create(:user, account: account, role: :agent) }
  let(:mike) { create(:user, account: account, role: :agent) }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(8)}"))
    [sam, sid, sue, cass, cole, cora, mike].each { |user| create(:inbox_member, user: user, inbox: inbox) }
    [sam, sid, sue].each { |user| create(:team_member, team: sales, user: user) }
    [cass, cole, cora].each { |user| create(:team_member, team: service, user: user) }
  end

  # A new instance, as each ring step makes
  def ring(dismissed: [])
    described_class.new(inbox: inbox, conversation: conversation, dismissed_user_ids: dismissed)
  end

  def call_for(user)
    other = create(:conversation, account: account, inbox: inbox)
    create(:call, account: account, inbox: inbox, conversation: other, contact: other.contact, status: 'in_progress', accepted_by_agent: user)
  end

  def offline(user)
    AccountUser.find_by(user: user, account: account).update!(availability: :offline)
  end

  it 'rings a call with no team as before: the free assignee alone, then everyone in the inbox' do
    conversation.update!(assignee: mike)

    expect(recipients.agents).to eq([mike])
    expect(recipients.next_group([mike.id])).to contain_exactly(sam, sid, sue, cass, cole, cora)
  end

  it 'rings everyone in the inbox when the team is set to inbox_agents' do
    service.update!(widen_calls: :inbox_agents)
    conversation.update!(team: service)
    conversation.update!(assignee: cass)
    call_for(cass)

    expect(recipients.agents).to contain_exactly(sam, sid, sue, cole, cora, mike)
  end

  it 'rings only the team when it is set to team_members' do
    conversation.update!(team: service)

    expect(recipients.agents).to contain_exactly(cass, cole, cora)

    conversation.update!(assignee: cass)

    expect(ring.agents).to eq([cass])
    expect(ring.next_group([cass.id])).to contain_exactly(cole, cora)
  end

  it 'never adds a non-member when the team rings in turn' do
    inbox.channel.update!(provider_config: inbox.channel.provider_config.merge('ring_strategy' => 'sequential'))
    conversation.update!(team: service)

    first = ring.agents
    second = ring.next_agent(first.map(&:id))
    third = ring.next_agent([*first, second].map(&:id))

    expect([*first, second, third]).to contain_exactly(cass, cole, cora)
    expect(ring.next_agent([cass.id, cole.id, cora.id])).to be_nil
  end

  it "uses the conversation's team over the assignee's" do
    conversation.update!(team: sales)
    conversation.update!(assignee: cass)

    expect(recipients.agents).to contain_exactly(sam, sid, sue)
  end

  it "uses the assignee's only team when the conversation has none" do
    conversation.update!(assignee: cass)

    expect(recipients.agents).to eq([cass])
    expect(recipients.next_group([cass.id])).to contain_exactly(cole, cora)
  end

  it 'rings the whole inbox for an assignee in two teams when the conversation has none' do
    create(:team_member, team: service, user: sid)
    conversation.update!(assignee: sid)

    expect(recipients.agents).to eq([sid])
    expect(recipients.next_group([sid.id])).to contain_exactly(sam, sue, cass, cole, cora, mike)
  end

  it 'rings a free assignee alone when the team is set to assignee_only, and adds nobody' do
    conversation.update!(team: sales)
    conversation.update!(assignee: sam)

    expect(recipients.agents).to eq([sam])
    expect(recipients.next_group([sam.id])).to eq([])
    expect(recipients.next_agent([sam.id])).to be_nil
    expect(recipients.nobody_online?).to be(false)
  end

  it 'lets the caller wait while an assignee_only assignee is on another call, ringing nobody' do
    conversation.update!(team: sales)
    conversation.update!(assignee: sam)
    call_for(sam)

    expect(recipients.agents).to eq([])
    expect(recipients.next_group([])).to eq([])
    expect(recipients.nobody_online?).to be(false)
  end

  it 'means nobody is online when an assignee_only assignee is offline, though teammates are free' do
    conversation.update!(team: sales)
    conversation.update!(assignee: sam)
    offline(sam)

    expect(recipients.agents).to eq([])
    expect(recipients.nobody_online?).to be(true)
  end

  it 'rings the whole assignee_only team when the assignee is outside it' do
    conversation.update!(team: sales)
    conversation.update!(assignee: mike)

    expect(recipients.agents).to contain_exactly(sam, sid, sue)
  end

  it 'adds nobody once an assignee_only assignee dismisses' do
    conversation.update!(team: sales)
    conversation.update!(assignee: sam)
    message = create(:message, account: account, inbox: inbox, conversation: conversation, content_type: 'voice_call')
    call = create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact, message: message,
                         ring_state: { 'ring_recipient_ids' => [sam.id] })

    Voice::RingDismissService.new(call: call, user: sam).perform
    Voice::RingNextAgentJob.perform_now(call.id, 2)

    expect(call.reload).to be_ringing
    expect(call.ring_state).to include('ring_recipient_ids' => [sam.id], 'dismissed_user_ids' => [sam.id], 'ring_step' => 3)
  end

  it 'rings the whole inbox from the next step once the team is deleted' do
    conversation.update!(team: service)

    expect(ring.agents).to contain_exactly(cass, cole, cora)

    service.destroy!
    conversation.reload

    expect(ring.next_group([cass.id, cole.id, cora.id])).to contain_exactly(sam, sid, sue, mike)
  end

  context 'with a WhatsApp inbox' do
    let(:inbox) { create(:channel_whatsapp, account: account, sync_templates: false, validate_provider_config: false).inbox }

    it 'follows the same assignee_only rule' do
      conversation.update!(team: sales)
      conversation.update!(assignee: sam)

      expect(recipients.agents).to eq([sam])
      expect(recipients.next_group([sam.id])).to eq([])

      offline(sam)

      expect(ring.agents).to eq([])
      expect(ring.nobody_online?).to be(true)
    end
  end
end
