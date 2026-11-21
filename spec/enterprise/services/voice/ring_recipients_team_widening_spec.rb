require 'rails_helper'

# Who a call rings past its assignee, by the widen_calls setting of the call's team. Sales rings
# nobody past its assignee and customer service rings only its members; mike is in no team.
# Teams do not auto-assign here, and a conversation's team is set before its assignee: changing the
# team clears an assignee outside it (AssignmentHandler), while a later reassignment to someone
# outside the team, the case these rows cover, keeps them.
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

  def routing(settings)
    channel = inbox.channel
    channel.provider_config = channel.provider_config.merge(settings)
    channel.save!(validate: false)
  end

  def availability(user, value)
    AccountUser.find_by(user: user, account: account).update!(availability: value)
  end

  # A call on another conversation, active unless a terminal status is given
  def call_for(user, status: 'in_progress')
    other = create(:conversation, account: account, inbox: inbox)
    create(:call, account: account, inbox: inbox, conversation: other, contact: other.contact, status: status, accepted_by_agent: user)
  end

  def end_call(call, ended_ago)
    call.update!(status: 'completed', started_at: (ended_ago + 60).seconds.ago, meta: { 'ended_at' => ended_ago.seconds.ago.to_i })
  end

  context 'without a team on the call' do
    it 'rings every online agent in the inbox when the call is unassigned' do
      expect(recipients.agents).to contain_exactly(sam, sid, sue, cass, cole, cora, mike)
    end

    it 'rings an assignee in no team alone, then everyone else in the inbox' do
      conversation.update!(assignee: mike)

      expect(recipients.agents).to eq([mike])
      expect(recipients.next_group([mike.id])).to contain_exactly(sam, sid, sue, cass, cole, cora)
    end

    it 'treats an assignee in two teams as no team when the conversation names none' do
      create(:team_member, team: service, user: sid)
      conversation.update!(assignee: sid)

      expect(recipients.agents).to eq([sid])
      expect(recipients.next_group([sid.id])).to contain_exactly(sam, sue, cass, cole, cora, mike)
    end

    it 'rings the whole inbox from the next step once the team is deleted mid-ring' do
      conversation.update!(team: service)

      expect(ring.agents).to contain_exactly(cass, cole, cora)

      service.destroy!
      conversation.reload

      expect(ring.next_group([cass.id, cole.id, cora.id])).to contain_exactly(sam, sid, sue, mike)
    end
  end

  context 'when the call team rings everyone in the inbox (inbox_agents)' do
    before do
      service.update!(widen_calls: :inbox_agents)
      conversation.update!(team: service)
    end

    it 'rings a free assignee alone, then everyone else in the inbox' do
      conversation.update!(assignee: cass)

      expect(recipients.agents).to eq([cass])
      expect(recipients.next_group([cass.id])).to contain_exactly(sam, sid, sue, cole, cora, mike)
    end

    it 'rings everyone else in the inbox when the assignee is busy' do
      conversation.update!(assignee: cass)
      availability(cass, :busy)

      expect(recipients.agents).to contain_exactly(sam, sid, sue, cole, cora, mike)
    end

    it 'rings everyone else in the inbox when the assignee is offline' do
      conversation.update!(assignee: cass)
      availability(cass, :offline)

      expect(recipients.agents).to contain_exactly(sam, sid, sue, cole, cora, mike)
    end

    it 'rings everyone else in the inbox when the assignee is on another call' do
      conversation.update!(assignee: cass)
      call_for(cass)

      expect(recipients.agents).to contain_exactly(sam, sid, sue, cole, cora, mike)
    end

    it 'rings an assignee outside the team alone first, as the inbox does' do
      conversation.update!(assignee: mike)

      expect(recipients.agents).to eq([mike])
    end

    it 'rings everyone in the inbox when the call is unassigned' do
      expect(recipients.agents).to contain_exactly(sam, sid, sue, cass, cole, cora, mike)
    end
  end

  context 'when the call team rings only its members (team_members)' do
    it 'rings a free assignee alone, then every free member of the team, never anyone else' do
      conversation.update!(assignee: cass)

      expect(recipients.agents).to eq([cass])
      expect(recipients.next_group([cass.id])).to contain_exactly(cole, cora)
      expect(ring.next_group([cass.id, cole.id])).to eq([cora])
      expect(ring.next_group([cass.id, cole.id, cora.id])).to be_empty
    end

    it 'rings the rest of the team when the assignee is busy' do
      conversation.update!(assignee: cass)
      availability(cass, :busy)

      expect(recipients.agents).to contain_exactly(cole, cora)
    end

    it 'rings the rest of the team when the assignee is offline' do
      conversation.update!(assignee: cass)
      availability(cass, :offline)

      expect(recipients.agents).to contain_exactly(cole, cora)
    end

    it 'rings the rest of the team when the assignee is on another call' do
      conversation.update!(assignee: cass)
      call_for(cass)

      expect(recipients.agents).to contain_exactly(cole, cora)
      expect(recipients.next_group([cole.id, cora.id])).to eq([])
    end

    it 'rings the whole team, never the assignee, when the assignee is outside the team' do
      conversation.update!(team: service)
      conversation.update!(assignee: mike)

      expect(recipients.agents).to contain_exactly(cass, cole, cora)
    end

    it "rings the conversation's team when the call is unassigned" do
      conversation.update!(team: service)

      expect(recipients.agents).to contain_exactly(cass, cole, cora)
      expect(recipients.next_group([])).to contain_exactly(cass, cole, cora)
    end

    it "lets the assignee's single team decide over a different conversation team" do
      conversation.update!(team: sales)
      conversation.update!(assignee: cass)

      expect(recipients.agents).to eq([cass])
      expect(recipients.next_group([cass.id])).to contain_exactly(cole, cora)
    end

    it 'means nobody is online when no member of the team is, though others in the inbox are' do
      conversation.update!(team: service)
      [cass, cole, cora].each { |user| availability(user, :offline) }

      expect(recipients.agents).to eq([])
      expect(recipients.nobody_online?).to be(true)
    end

    it 'lets the caller wait when the assignee is offline and the rest of the team is on calls' do
      conversation.update!(assignee: cass)
      availability(cass, :offline)
      [cole, cora].each { |user| call_for(user) }

      expect(recipients.agents).to eq([])
      expect(recipients.nobody_online?).to be(false)
    end

    it 'rings in turn from the longest idle member and walks only the team when the assignee is busy' do
      routing('ring_strategy' => 'sequential')
      conversation.update!(assignee: cass)
      call_for(cass)
      end_call(call_for(cole), 600)

      expect(ring.agents).to eq([cora])
      expect(ring.next_agent([cora.id])).to eq(cole)
      expect(ring.next_agent([cora.id, cole.id])).to be_nil
    end

    it 'never adds a non-member when ringing in turn, the call unassigned' do
      routing('ring_strategy' => 'sequential')
      conversation.update!(team: service)

      first = ring.agents
      second = ring.next_agent(first.map(&:id))
      third = ring.next_agent([*first, second].map(&:id))

      expect([*first, second, third]).to contain_exactly(cass, cole, cora)
      expect(ring.next_agent([cass.id, cole.id, cora.id])).to be_nil
    end

    context 'when every member is busy' do
      before { conversation.update!(team: service) }

      it 'lets the caller wait while all are on calls, and rings the first to hang up' do
        calls = [cass, cole, cora].index_with { |user| call_for(user) }

        expect(ring.agents).to eq([])
        expect(ring.nobody_online?).to be(false)

        end_call(calls[cole], 5)

        expect(ring.next_group([])).to eq([cole])
      end

      it 'rings a member who hung up once their wrap-up time ends or that conversation is resolved' do
        routing('call_cooldown_seconds' => 60)
        calls = [cass, cole, cora].index_with { |user| call_for(user) }
        end_call(calls[cole], 5)

        expect(ring.next_group([])).to eq([])
        travel(2.minutes) { expect(ring.next_group([])).to eq([cole]) }

        calls[cole].conversation.update!(status: :resolved)

        expect(ring.next_group([])).to eq([cole])
      end

      it 'lets the caller wait when every member is in wrap-up time, as when all are on calls' do
        routing('call_cooldown_seconds' => 60)
        [cass, cole, cora].each { |user| end_call(call_for(user), 10) }

        expect(ring.agents).to eq([])
        expect(ring.nobody_online?).to be(false)
      end
    end
  end

  context 'when the call team rings nobody past its assignee (assignee_only)' do
    it 'rings a free assignee alone and never widens' do
      conversation.update!(assignee: sam)

      expect(recipients.agents).to eq([sam])
      expect(recipients.next_group([sam.id])).to eq([])
      expect(recipients.next_agent([sam.id])).to be_nil
      expect(recipients.nobody_online?).to be(false)
    end

    it 'means nobody is online when the assignee is busy, though teammates are free' do
      conversation.update!(assignee: sam)
      availability(sam, :busy)

      expect(recipients.agents).to eq([])
      expect(recipients.nobody_online?).to be(true)
    end

    it 'means nobody is online when the assignee is offline, though teammates are free' do
      conversation.update!(assignee: sam)
      availability(sam, :offline)

      expect(recipients.agents).to eq([])
      expect(recipients.nobody_online?).to be(true)
    end

    it 'means nobody is online when the assignee is on another call, and rings nobody else' do
      conversation.update!(assignee: sam)
      call_for(sam)

      expect(recipients.agents).to eq([])
      expect(recipients.nobody_online?).to be(true)
      expect(recipients.next_group([])).to eq([])
    end

    it 'rings the whole team when the assignee is outside it' do
      conversation.update!(team: sales)
      conversation.update!(assignee: mike)

      expect(recipients.agents).to contain_exactly(sam, sid, sue)
      expect(recipients.nobody_online?).to be(false)
    end

    it 'rings the whole team when the call is unassigned, as a team that rings only its members does' do
      conversation.update!(team: sales)

      expect(recipients.agents).to contain_exactly(sam, sid, sue)
      expect(recipients.next_group([sam.id])).to contain_exactly(sid, sue)
    end

    it 'still rings the assignee alone when the inbox does not ring the assignee first' do
      routing('assignee_rings_first' => false)
      conversation.update!(assignee: sam)

      expect(recipients.agents).to eq([sam])
      expect(recipients.nobody_online?).to be(false)
    end

    it 'widens to the team members from the next step once the team rings its members' do
      conversation.update!(assignee: sam)

      expect(ring.next_group([sam.id])).to eq([])

      sales.update!(widen_calls: :team_members)

      expect(ring.agents).to eq([sam])
      expect(ring.next_group([sam.id])).to contain_exactly(sid, sue)
    end

    it 'adds nobody once the held assignee dismisses, so the call ends missed at the ring timeout' do
      conversation.update!(assignee: sam)
      message = create(:message, account: account, inbox: inbox, conversation: conversation, content_type: 'voice_call')
      call = create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact, message: message,
                           ring_state: { 'ring_recipient_ids' => [sam.id] })

      Voice::RingDismissService.new(call: call, user: sam).perform
      Voice::RingNextAgentJob.perform_now(call.id, 2)

      expect(ring(dismissed: [sam.id]).next_group([sam.id])).to eq([])
      expect(call.reload).to be_ringing
      expect(call.ring_state).to include('ring_recipient_ids' => [sam.id], 'dismissed_user_ids' => [sam.id], 'ring_step' => 3)
    end
  end

  context 'when the call is reassigned to another team mid-ring' do
    it 'adds nobody, and the next call rings the new team' do
      conversation.update!(assignee: cass)

      expect(recipients.next_group([sam.id])).to eq([])
      expect(recipients.next_agent([sam.id])).to be_nil
      expect(ring.agents).to eq([cass])
      expect(ring.next_group([cass.id])).to contain_exactly(cole, cora)
    end
  end

  context 'with an assignee in two teams' do
    it 'lets the conversation team decide, and rings the assignee as a member of it' do
      create(:team_member, team: service, user: sid)
      conversation.update!(team: service)
      conversation.update!(assignee: sid)

      expect(recipients.agents).to eq([sid])
      expect(recipients.next_group([sid.id])).to contain_exactly(cass, cole, cora)
    end
  end

  context 'with a team created without the setting' do
    it 'rings everyone in the inbox, as before the setting existed' do
      support = Team.create!(account: account, name: 'support')
      conversation.update!(team: support)

      expect(support).to be_widen_calls_inbox_agents
      expect(recipients.agents).to contain_exactly(sam, sid, sue, cass, cole, cora, mike)
    end
  end

  context 'with a team created through the API without the setting', type: :request do
    it 'rings everyone in the inbox, the administrator who made it included' do
      administrator = create(:user, account: account, role: :administrator)
      post "/api/v1/accounts/#{account.id}/teams", params: { name: 'support' }, headers: administrator.create_new_auth_token, as: :json
      conversation.update!(team: Team.find_by!(account: account, name: 'support'))

      expect(response).to have_http_status(:success)
      expect(recipients.agents).to contain_exactly(sam, sid, sue, cass, cole, cora, mike, administrator)
    end
  end

  context 'with a WhatsApp inbox' do
    let(:inbox) { create(:channel_whatsapp, account: account, sync_templates: false, validate_provider_config: false).inbox }

    it 'rings only the team when the team rings only its members' do
      conversation.update!(assignee: cass)

      expect(recipients.agents).to eq([cass])
      expect(recipients.next_group([cass.id])).to contain_exactly(cole, cora)
    end

    it 'rings a free held assignee alone and never widens' do
      conversation.update!(assignee: sam)

      expect(recipients.agents).to eq([sam])
      expect(recipients.next_group([sam.id])).to eq([])
    end

    it 'rings the team when the held assignee is offline, since a WhatsApp call has no missed-call message to end on' do
      conversation.update!(assignee: sam)
      availability(sam, :offline)

      expect(recipients.agents).to contain_exactly(sid, sue)
      expect(recipients.nobody_online?).to be(false)
    end

    it 'rings the team once the held assignee dismisses' do
      conversation.update!(assignee: sam)

      expect(ring(dismissed: [sam.id]).next_group([sam.id])).to contain_exactly(sid, sue)
    end
  end

  # Every cell of a team that rings only its members or nobody past its assignee: whatever the
  # assignee, the inbox's strategy and the other members' state, the call rings nobody outside the
  # team, and the caller waits only while an online team is all busy
  context 'with the invariant sweep' do
    def in_team?(assignee)
      [:free, :on_call, :offline].include?(assignee)
    end

    # An assignee in the team sits on a conversation that names sales, so their own team must win;
    # otherwise the conversation names customer service
    def arrange(assignee, others)
      assigned = { free: cass, on_call: cass, offline: cass, outside_team: mike }[assignee]
      conversation.update!(team: in_team?(assignee) ? sales : service)
      conversation.update!(assignee: assigned)
      call_for(cass) if assignee == :on_call
      availability(cass, :offline) if assignee == :offline
      [cole, cora].each { |user| call_for(user) } if others == :on_calls
    end

    def free_members(assignee, others)
      [*([cass] unless [:on_call, :offline].include?(assignee)), *([cole, cora] if others == :free)]
    end

    # Everyone the call can ever ring: the start, the next group and every step in turn
    def everyone_rung
      rung = ring.agents
      group = ring.next_group(rung.map(&:id))
      steps = []
      while (step = ring.next_agent((rung + steps).map(&:id)))
        steps << step
        break if steps.size > 10
      end
      rung + group + steps
    end

    [:team_members, :assignee_only].product([:none, :free, :on_call, :offline, :outside_team], [:simultaneous, :sequential], [:free, :on_calls])
                                   .each do |value, assignee, strategy, others|
      context "with #{value}, the assignee #{assignee}, ringing #{strategy}, the other members #{others}" do
        it 'rings only the team, and waits only while an online team is all busy' do
          service.update!(widen_calls: value)
          routing('ring_strategy' => strategy.to_s)
          arrange(assignee, others)
          agents = ring.agents

          expect(everyone_rung - [cass, cole, cora]).to eq([])
          if value == :assignee_only && in_team?(assignee)
            expect(agents).to eq(assignee == :free ? [cass] : [])
            expect(ring.nobody_online?).to eq(agents.empty?)
          else
            expect(agents.empty?).to eq(free_members(assignee, others).empty?)
            expect(ring.nobody_online?).to be(false)
          end
        end
      end
    end
  end
end
