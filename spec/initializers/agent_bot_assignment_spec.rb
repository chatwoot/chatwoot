require 'rails_helper'

# The two modules live in config/initializers/agent_bot_assignment.rb and are prepended at boot, so
# there is no class of ours to name here. What is covered is what an agent sees: which bots the
# assignee dropdown offers, and the activity line a bot assignment leaves (#721).
describe 'AgentBotAssignment', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent, name: 'Assigner') }
  let(:inbox) { create(:inbox, account: account) }
  let(:other_inbox) { create(:inbox, account: account) }

  before do
    create(:inbox_member, user: agent, inbox: inbox)
    create(:inbox_member, user: agent, inbox: other_inbox)
  end

  describe 'the assignee dropdown' do
    let!(:inbox_bot) { create(:agent_bot, account: account, name: 'Inbox bot') }
    let!(:other_inbox_bot) { create(:agent_bot, account: account, name: 'Other inbox bot') }
    let!(:unconnected_bot) { create(:agent_bot, account: account, name: 'Unconnected bot') }
    let!(:global_bot) { create(:agent_bot, account: nil, name: 'Global bot') }

    before do
      create(:agent_bot_inbox, inbox: inbox, agent_bot: inbox_bot)
      create(:agent_bot_inbox, inbox: other_inbox, agent_bot: other_inbox_bot)
    end

    def payload(inboxes, include_ai_assignees: true)
      params = { inbox_ids: inboxes.map(&:id) }
      params[:include_ai_assignees] = true if include_ai_assignees
      get "/api/v1/accounts/#{account.id}/assignable_agents", params: params, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      response.parsed_body['payload']
    end

    def offered_bots(*inboxes)
      payload(inboxes).select { |owner| owner['assignee_type'] == 'AgentBot' }.pluck('name')
    end

    it "offers the inbox's own bot, the unconnected bots and the global ones, and not a bot of another inbox" do
      expect(offered_bots(inbox)).to contain_exactly(inbox_bot.name, unconnected_bot.name, global_bot.name)
    end

    it 'offers the same users with and without AI assignees' do
      with_bots = payload([inbox]).reject { |owner| owner['assignee_type'] == 'AgentBot' }.pluck('id')

      expect(with_bots).to match_array(payload([inbox], include_ai_assignees: false).pluck('id'))
    end

    it 'offers no bot without the AI assignees flag' do
      expect(payload([inbox], include_ai_assignees: false).pluck('name')).not_to include(inbox_bot.name, unconnected_bot.name)
    end

    it 'keeps offering the inbox bot when it also answers another inbox' do
      shared_inbox = create(:inbox, account: account)
      create(:agent_bot_inbox, inbox: shared_inbox, agent_bot: inbox_bot)

      expect(offered_bots(inbox)).to include(inbox_bot.name)
    end

    it 'does not offer a global bot connected to another inbox of the account' do
      other_inbox.agent_bot_inbox.update!(agent_bot: global_bot)

      expect(offered_bots(inbox)).not_to include(global_bot.name)
    end

    it 'does not offer a bot whose connection to another inbox is inactive' do
      other_inbox.agent_bot_inbox.update!(status: :inactive)

      expect(offered_bots(inbox)).not_to include(other_inbox_bot.name)
    end

    it 'does not offer the inbox bot while its connection is inactive' do
      inbox.agent_bot_inbox.update!(status: :inactive)

      expect(offered_bots(inbox)).not_to include(inbox_bot.name)
    end

    it 'does not offer the inbox bot while its connection here is inactive and it answers another inbox' do
      create(:agent_bot_inbox, inbox: create(:inbox, account: account), agent_bot: inbox_bot)
      inbox.agent_bot_inbox.update!(status: :inactive)

      expect(offered_bots(inbox)).not_to include(inbox_bot.name)
    end

    # An observer gets the inbox's events and never answers, so owning a conversation strands it.
    it 'does not offer a bot that observes another inbox' do
      create(:agent_bot_observer, inbox: other_inbox, agent_bot: unconnected_bot)

      expect(offered_bots(inbox)).not_to include(unconnected_bot.name)
    end

    it 'does not offer a bot that observes this inbox' do
      create(:agent_bot_observer, inbox: inbox, agent_bot: unconnected_bot)

      expect(offered_bots(inbox)).not_to include(unconnected_bot.name)
    end

    it 'keeps offering the inbox bot when it also observes another inbox' do
      create(:agent_bot_observer, inbox: other_inbox, agent_bot: inbox_bot)

      expect(offered_bots(inbox)).to include(inbox_bot.name)
    end

    it 'ignores the connections and observations a bot has in another account' do
      elsewhere = create(:inbox)
      create(:agent_bot_inbox, inbox: elsewhere, agent_bot: global_bot)
      create(:agent_bot_observer, inbox: create(:inbox), agent_bot: global_bot)

      expect(offered_bots(inbox)).to include(global_bot.name)
    end

    context 'with several inboxes' do
      it 'offers only the bots that pass for every inbox' do
        expect(offered_bots(inbox, other_inbox)).to contain_exactly(unconnected_bot.name, global_bot.name)
      end

      it 'offers a bot that answers every one of them' do
        other_inbox.agent_bot_inbox.update!(agent_bot: inbox_bot)

        # The bot that lost the other inbox answers none now, so it is offered like any unconnected bot.
        expect(offered_bots(inbox, other_inbox)).to contain_exactly(inbox_bot.name, other_inbox_bot.name, unconnected_bot.name, global_bot.name)
      end
    end
  end

  describe 'the activity a bot assignment writes' do
    let(:agent_bot) { create(:agent_bot, account: account, name: 'Assigned bot') }
    let(:conversation) { create(:conversation, account: account, inbox: inbox) }

    before { Current.user = agent }

    after { Current.reset }

    def activity_contents
      ActiveJob::Base.queue_adapter.enqueued_jobs
                     .select { |job| job['job_class'] == 'Conversations::ActivityMessageJob' }
                     .map { |job| job['arguments'].second['content'] }
    end

    def assign(assignee_id, assignee_type = nil)
      conversation.reload
      clear_enqueued_jobs
      Conversations::AssignmentService.new(conversation: conversation, assignee_id: assignee_id, assignee_type: assignee_type).perform
    end

    it 'names the bot and who assigned it, instead of an unassignment, when the bot replaces a human' do
      conversation.update!(assignee: agent)

      assign(agent_bot.id, 'AgentBot')

      expect(activity_contents).to include("Assigned to #{agent_bot.name} by #{agent.name}")
      expect(activity_contents).not_to include("Conversation unassigned by #{agent.name}")
    end

    it 'names the bot when the conversation had no owner' do
      assign(agent_bot.id, 'AgentBot')

      expect(activity_contents).to include("Assigned to #{agent_bot.name} by #{agent.name}")
    end

    it 'names the new bot when one bot takes over from another' do
      conversation.update!(ai_assignee: create(:agent_bot, account: account))

      assign(agent_bot.id, 'AgentBot')

      expect(activity_contents).to include("Assigned to #{agent_bot.name} by #{agent.name}")
    end

    it 'still writes the user assignment when an agent takes the conversation from the bot' do
      teammate = create(:user, account: account, role: :agent, name: 'Teammate')
      create(:inbox_member, user: teammate, inbox: inbox)
      conversation.update!(ai_assignee: agent_bot, status: :pending)

      assign(teammate.id)

      expect(activity_contents).to include("Assigned to #{teammate.name} by #{agent.name}")
      expect(activity_contents.grep(/#{Regexp.escape(agent_bot.name)}/)).to be_empty
    end

    it 'writes nothing about the bot the inbox hands a new conversation' do
      create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
      clear_enqueued_jobs

      create(:conversation, account: account, inbox: inbox)

      expect(activity_contents.grep(/#{Regexp.escape(agent_bot.name)}/)).to be_empty
    end

    it 'writes nothing when no one is behind the change' do
      Current.reset

      assign(agent_bot.id, 'AgentBot')

      expect(activity_contents.grep(/#{Regexp.escape(agent_bot.name)}/)).to be_empty
    end

    it 'leaves the team line alone when the team changes in the same save' do
      team = create(:team, account: account)

      conversation.update!(team: team, ai_assignee: agent_bot)

      expect(activity_contents).to include("Assigned to #{team.name} by #{agent.name}")
      expect(activity_contents.grep(/#{Regexp.escape(agent_bot.name)}/)).to be_empty
    end
  end

  # The human decision on #721: the API keeps upstream's contract, and a bot of another inbox can
  # still be assigned on purpose (chatwoot/chatwoot#12836).
  it 'still assigns a bot of another inbox through the API' do
    foreign_bot = create(:agent_bot, account: account)
    create(:agent_bot_inbox, inbox: other_inbox, agent_bot: foreign_bot)
    conversation = create(:conversation, account: account, inbox: inbox)

    post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/assignments",
         params: { assignee_id: foreign_bot.id, assignee_type: 'AgentBot' },
         headers: agent.create_new_auth_token,
         as: :json

    expect(response).to have_http_status(:success)
    expect(conversation.reload.ai_assignee).to eq(foreign_bot)
  end
end
