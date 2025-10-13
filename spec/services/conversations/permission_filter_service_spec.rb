require 'rails_helper'

RSpec.describe Conversations::PermissionFilterService do
  let(:account) { create(:account) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let!(:another_conversation) { create(:conversation, account: account, inbox: inbox) }
  let!(:team_conversation) { create(:conversation, account: account, inbox: other_inbox, team: team) }
  let!(:inaccessible_conversation) { create(:conversation, account: account, inbox: other_inbox) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:team_agent) { create(:user, account: account, role: :agent) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:other_inbox) { create(:inbox, account: account) }
  let!(:team) { create(:team, account: account) }

  # This inbox_member is used to establish the agent's access to the inbox
  before do
    create(:inbox_member, user: agent, inbox: inbox)
    create(:team_member, user: team_agent, team: team)
  end

  describe '#perform' do
    context 'when user is an administrator' do
      it 'returns all conversations' do
        result = described_class.new(
          account.conversations,
          admin,
          account
        ).perform

        expect(result).to include(conversation)
        expect(result).to include(another_conversation)
        expect(result).to include(team_conversation)
        expect(result).to include(inaccessible_conversation)
        expect(result.count).to eq(4)
      end
    end

    context 'when user is an agent' do
      context 'with inbox access only' do
        it 'returns conversations from assigned inboxes' do
          result = described_class.new(
            account.conversations,
            agent,
            account
          ).perform

          expect(result).to include(conversation)
          expect(result).to include(another_conversation)
          expect(result).not_to include(team_conversation)
          expect(result).not_to include(inaccessible_conversation)
          expect(result.count).to eq(2)
        end
      end

      context 'with team access only' do
        it 'returns conversations from assigned teams' do
          result = described_class.new(
            account.conversations,
            team_agent,
            account
          ).perform

          expect(result).to include(team_conversation)
          expect(result).not_to include(conversation)
          expect(result).not_to include(another_conversation)
          expect(result).not_to include(inaccessible_conversation)
          expect(result.count).to eq(1)
        end
      end

      context 'with both inbox and team access' do
        let(:agent_with_both) { create(:user, account: account, role: :agent) }

        before do
          create(:inbox_member, user: agent_with_both, inbox: inbox)
          create(:team_member, user: agent_with_both, team: team)
        end

        it 'returns conversations from both assigned inboxes and teams' do
          result = described_class.new(
            account.conversations,
            agent_with_both,
            account
          ).perform

          expect(result).to include(conversation)
          expect(result).to include(another_conversation)
          expect(result).to include(team_conversation)
          expect(result).not_to include(inaccessible_conversation)
          expect(result.count).to eq(3)
        end
      end

      context 'with no access' do
        let(:agent_no_access) { create(:user, account: account, role: :agent) }

        it 'returns no conversations' do
          result = described_class.new(
            account.conversations,
            agent_no_access,
            account
          ).perform

          expect(result).to be_empty
          expect(result.count).to eq(0)
        end
      end
    end
  end
end
