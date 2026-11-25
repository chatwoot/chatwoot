require 'rails_helper'

# The client decides which conversations belong in the "Unassigned" and "Mine" tabs by filtering the
# store locally, while the badge next to each tab is a count the server sent. Nothing used to tie the
# two definitions together, so they could drift apart with every test on both sides still green: the
# server counted a bot-held conversation as assigned and the client listed it as unassigned, and the
# tab only disagreed with its own badge once a visit to "All" had loaded those conversations into the
# store (#416).
#
# This spec is the tie. It asks the real endpoint what each tab holds and writes the answer next to
# the client's own specs, which replay it through the store getters. A change to the server's
# semantics rewrites the fixture here and breaks the client spec that reads it.
RSpec.describe 'Conversation assignee contract', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  # Same integer as the agent, which is a real payload: bot ids come from their own table.
  let(:agent_bot) { create(:agent_bot, account: account, id: agent.id) }

  let(:contract_path) do
    Rails.root.join('app/javascript/dashboard/store/modules/conversations/specs/contracts/assigneeContract.json')
  end

  let!(:unassigned_conversation) { create(:conversation, account: account, inbox: inbox, status: :open) }
  let!(:human_conversation) { create(:conversation, account: account, inbox: inbox, status: :open, assignee: agent) }
  let!(:bot_conversation) do
    create(:conversation, account: account, inbox: inbox, status: :open, ai_assignee: agent_bot)
  end

  # Ids the fixture can be diffed on: the conversations by the role they play here, and both
  # assignees onto the single integer they share. The payload identifies a conversation by its
  # `display_id`, which is what the client stores as `id`.
  let(:conversation_ids) do
    {
      unassigned_conversation.display_id => 1,
      human_conversation.display_id => 2,
      bot_conversation.display_id => 3
    }
  end
  let(:normalized_assignee_id) { 100 }

  before { create(:inbox_member, user: agent, inbox: inbox) }

  def list(assignee_type)
    get "/api/v1/accounts/#{account.id}/conversations",
        params: { status: 'open', assignee_type: assignee_type },
        headers: agent.create_new_auth_token,
        as: :json

    expect(response).to have_http_status(:success)
    JSON.parse(response.body, symbolize_names: true)[:data]
  end

  def normalize(conversation)
    assignee = conversation[:meta][:assignee]

    {
      id: conversation_ids.fetch(conversation[:id]),
      status: conversation[:status],
      inbox_id: 1,
      labels: conversation[:labels],
      meta: {
        assignee: assignee && { id: normalized_assignee_id },
        assignee_type: conversation[:meta][:assignee_type]
      }
    }
  end

  it 'matches the assignee semantics the client replays' do
    all = list('all')
    unassigned = list('unassigned')
    mine = list('me')

    contract = {
      _generated_by: 'spec/contracts/conversation_assignee_contract_spec.rb',
      _regenerate_with: 'UPDATE_CONTRACTS=1 bundle exec rspec spec/contracts/conversation_assignee_contract_spec.rb',
      current_user_id: normalized_assignee_id,
      # What a visit to the "All" tab loads into the store, which is every conversation the tabs
      # filter locally from.
      conversations: all[:payload].map { |conversation| normalize(conversation) }.sort_by { |c| c[:id] },
      server: {
        unassigned_ids: unassigned[:payload].map { |c| conversation_ids.fetch(c[:id]) }.sort,
        mine_ids: mine[:payload].map { |c| conversation_ids.fetch(c[:id]) }.sort,
        counts: all[:meta].slice(:mine_count, :assigned_count, :unassigned_count, :all_count)
      }
    }

    json = "#{JSON.pretty_generate(contract)}\n"

    if ENV.fetch('UPDATE_CONTRACTS', nil)
      contract_path.write(json)
    else
      expect(contract_path.read).to eq(json), <<~MESSAGE
        The conversation assignee contract changed. If the new behaviour is intended, regenerate the
        fixture with `#{contract[:_regenerate_with]}` and run the client spec that reads it
        (assigneeContract.spec.js), which is what keeps the tabs agreeing with their badges.
      MESSAGE
    end
  end
end
