require 'rails_helper'

RSpec.describe SearchIndexing::AssociationRefreshJob do
  self.use_transactional_tests = false
  include_context 'with conversation search queue'

  let(:account) { create(:account) }

  before do
    allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(true)
    account.enable_features!('advanced_search_conversations')
  end

  after do
    allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(false)
    users = account.users.to_a
    perform_enqueued_jobs(only: ActiveRecord::DestroyAssociationAsyncJob) do
      account.conversations.destroy_all
      account.contacts.destroy_all
      account.inboxes.destroy_all
      account.destroy!
      users.each(&:destroy!)
    end
    Audited::Audit.where(associated: account).or(Audited::Audit.where(auditable: account)).delete_all
  end

  it 'captures team nullification without collecting every conversation ID in the destroy transaction' do
    team = create(:team, account: account)
    conversation = create(:conversation, account: account, team: team)
    expect { team.destroy! }.to have_enqueued_job(described_class).with('team_id', team.id, account.id)
    expect(conversation.reload.team_id).to be_nil
  end

  it 'captures bulk unassignment when removing an account agent' do
    user = create(:user, account: account)
    conversation = create(:conversation, account: account, assignee: user)
    expect { Agents::DestroyJob.perform_now(account, user) }.to have_enqueued_job(described_class).with('assignee_id', user.id, account.id)
    expect(conversation.reload.assignee_id).to be_nil
  end

  it 'captures direct user deletion' do
    user = create(:user, account: account)
    conversation = create(:conversation, account: account, assignee: user)
    expect { user.destroy! }.to have_enqueued_job(described_class).with('assignee_id', user.id, account.id)
    expect(conversation.reload.assignee_id).to be_nil
  end

  it 'captures bot deletion' do
    bot = create(:agent_bot, account: account)
    expect { bot.destroy! }.to have_enqueued_job(described_class).with('assignee_agent_bot_id', bot.id, account.id)
  end

  it 'scopes global bot cleanup to accounts with assigned conversations' do
    bot = create(:agent_bot, account: nil)
    conversation = create(:conversation, account: account, ai_assignee: bot)
    expect { bot.destroy! }.to have_enqueued_job(described_class).with('assignee_agent_bot_id', bot.id, account.id)
    expect(conversation.reload.assignee_agent_bot_id).to be_nil
  end

  it 'captures Captain assistant deletion' do
    assistant = create(:captain_assistant, account: account)
    expect { assistant.destroy! }.to have_enqueued_job(described_class).with('assignee_agent_bot_id', assistant.id, account.id)
  end
end
