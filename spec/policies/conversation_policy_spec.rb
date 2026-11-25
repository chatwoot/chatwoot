require 'rails_helper'

RSpec.describe ConversationPolicy, type: :policy do
  subject { described_class }

  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:administrator_context) { { user: administrator, account: account, account_user: administrator.account_users.find_by(account: account) } }
  let(:agent_context) { { user: agent, account: account, account_user: agent.account_users.find_by(account: account) } }

  let(:conversation) { create(:conversation, account: account) }

  permissions :destroy? do
    context 'when user is an administrator' do
      it 'allows destroy' do
        expect(subject).to permit(administrator_context, conversation)
      end
    end

    context 'when user is an agent' do
      it 'denies destroy' do
        expect(subject).not_to permit(agent_context, conversation)
      end
    end
  end

  permissions :index? do
    context 'when user is authenticated' do
      it 'allows index' do
        expect(subject).to permit(agent_context, conversation)
      end
    end
  end

  permissions :show? do
    context 'when user is an administrator' do
      it 'allows access' do
        expect(subject).to permit(administrator_context, conversation)
      end
    end

    context 'when agent has inbox access' do
      let(:inbox) { create(:inbox, account: account) }
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }

      before { create(:inbox_member, user: agent, inbox: inbox) }

      it 'allows access' do
        expect(subject).to permit(agent_context, conversation)
      end
    end

    context 'when agent has team access' do
      let(:team) { create(:team, account: account) }
      let(:conversation) { create(:conversation, :with_team, account: account, team: team) }

      before { create(:team_member, team: team, user: agent) }

      it 'allows access' do
        expect(subject).to permit(agent_context, conversation)
      end
    end

    context 'when agent lacks inbox and team access' do
      let(:conversation) { create(:conversation, account: account) }

      it 'denies access' do
        expect(subject).not_to permit(agent_context, conversation)
      end
    end
  end

  permissions :read_receipt? do
    let(:inbox) { create(:inbox, account: account) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox) }
    let(:agent_bot) { create(:agent_bot, account: account) }
    let(:agent_bot_context) { { user: agent_bot, account: account, account_user: nil } }

    context 'when the bot serves the inbox' do
      before { create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot) }

      it 'allows the receipt' do
        expect(subject).to permit(agent_bot_context, conversation)
      end
    end

    context 'when the bot is the conversation assignee' do
      before { conversation.update!(ai_assignee: agent_bot) }

      it 'allows the receipt' do
        expect(subject).to permit(agent_bot_context, conversation)
      end
    end

    # An operator switching the bot off must stop it putting blue ticks on the contact's
    # phone, which is what `active?` means everywhere else the codebase asks whether a bot
    # serves an inbox.
    context 'when the association is inactive' do
      before { create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot, status: :inactive) }

      it 'denies the receipt' do
        expect(subject).not_to permit(agent_bot_context, conversation)
      end
    end

    context 'when the bot serves no inbox on the conversation' do
      it 'denies the receipt even though show? allows it' do
        expect(subject).not_to permit(agent_bot_context, conversation)
        expect(described_class.new(agent_bot_context, conversation).show?).to be(true)
      end
    end

    context 'when the caller is an agent' do
      before { create(:inbox_member, user: agent, inbox: inbox) }

      it 'falls back to show?' do
        expect(subject).to permit(agent_context, conversation)
      end
    end
  end
end
