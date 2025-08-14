require 'rails_helper'

RSpec.describe ConversationPolicy, type: :policy do
  subject { described_class }

  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:administrator_context) { { user: administrator, account: account, account_user: administrator.account_users.first } }
  let(:agent_context) { { user: agent, account: account, account_user: agent.account_users.first } }

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
    let(:inbox) { create(:inbox, account: account) }
    let(:team) { create(:team, account: account) }
    let(:conversation_with_inbox) { create(:conversation, account: account, inbox: inbox) }
    let(:conversation_with_team) { create(:conversation, account: account, inbox: other_inbox, team: team) }
    let(:other_inbox) { create(:inbox, account: account) }
    let(:inaccessible_conversation) { create(:conversation, account: account, inbox: other_inbox) }

    context 'when user is an administrator' do
      it 'allows show for any conversation' do
        expect(subject).to permit(administrator_context, conversation_with_inbox)
        expect(subject).to permit(administrator_context, conversation_with_team)
        expect(subject).to permit(administrator_context, inaccessible_conversation)
      end
    end

    context 'when user is an agent' do
      context 'with inbox access' do
        before do
          create(:inbox_member, user: agent, inbox: inbox)
        end

        it 'allows show for conversations in assigned inbox' do
          expect(subject).to permit(agent_context, conversation_with_inbox)
        end

        it 'denies show for conversations in non-assigned inbox' do
          expect(subject).not_to permit(agent_context, conversation_with_team)
          expect(subject).not_to permit(agent_context, inaccessible_conversation)
        end
      end

      context 'with team access' do
        before do
          create(:team_member, user: agent, team: team)
        end

        it 'allows show for conversations assigned to user team' do
          expect(subject).to permit(agent_context, conversation_with_team)
        end

        it 'denies show for conversations not assigned to user team' do
          expect(subject).not_to permit(agent_context, conversation_with_inbox)
          expect(subject).not_to permit(agent_context, inaccessible_conversation)
        end
      end

      context 'with both inbox and team access' do
        before do
          create(:inbox_member, user: agent, inbox: inbox)
          create(:team_member, user: agent, team: team)
        end

        it 'allows show for conversations from both inbox and team' do
          expect(subject).to permit(agent_context, conversation_with_inbox)
          expect(subject).to permit(agent_context, conversation_with_team)
        end

        it 'denies show for inaccessible conversations' do
          expect(subject).not_to permit(agent_context, inaccessible_conversation)
        end
      end

      context 'with no access' do
        it 'denies show for all conversations' do
          expect(subject).not_to permit(agent_context, conversation_with_inbox)
          expect(subject).not_to permit(agent_context, conversation_with_team)
          expect(subject).not_to permit(agent_context, inaccessible_conversation)
        end
      end
    end
  end
end
