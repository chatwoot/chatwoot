require 'rails_helper'

describe ::ConversationFinder do
  subject(:conversation_finder) { described_class.new(user_1, params) }

  let!(:account) { create(:account) }
  let!(:user_1) { create(:user, account: account) }
  let!(:user_2) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account, enable_auto_assignment: false) }

  before do
    create(:inbox_member, user: user_1, inbox: inbox)
    create(:inbox_member, user: user_2, inbox: inbox)
    create(:conversation, account: account, inbox: inbox, assignee: user_1)
    create(:conversation, account: account, inbox: inbox, assignee: user_1)
    create(:conversation, account: account, inbox: inbox, assignee: user_1, status: 'resolved')
    create(:conversation, account: account, inbox: inbox, assignee: user_2)
    # unassigned conversation
    create(:conversation, account: account, inbox: inbox)
    Current.account = account
  end

  describe '#perform' do
    context 'with status' do
      let(:params) { { status: 'open', assignee_type: 'me' } }

      it 'filter conversations by status' do
        result = conversation_finder.perform
        expect(result[:conversations].length).to be 2
      end
    end

    context 'with assignee_type all' do
      let(:params) { { assignee_type: 'all' } }

      it 'filter conversations by assignee type all' do
        result = conversation_finder.perform
        expect(result[:conversations].length).to be 4
      end
    end

    context 'with assignee_type unassigned' do
      let(:params) { { assignee_type: 'unassigned' } }

      it 'filter conversations by assignee type unassigned' do
        result = conversation_finder.perform
        expect(result[:conversations].length).to be 1
      end
    end

    context 'with assignee_type assigned' do
      let(:params) { { assignee_type: 'assigned' } }

      it 'filter conversations by assignee type assigned' do
        result = conversation_finder.perform
        expect(result[:conversations].length).to be 3
      end

      it 'returns the correct meta' do
        result = conversation_finder.perform
        expect(result[:count]).to eq({
                                       mine_count: 2,
                                       assigned_count: 3,
                                       unassigned_count: 1,
                                       all_count: 4
                                     })
      end
    end

    context 'with team' do
      let(:team) { create(:team, account: account) }
      let(:params) { { team_id: team.id } }

      it 'filter conversations by team' do
        create(:conversation, account: account, inbox: inbox, team: team)
        result = conversation_finder.perform
        expect(result[:conversations].length).to be 1
      end
    end

    context 'with labels' do
      let(:params) { { labels: ['resolved'] } }

      it 'filter conversations by labels' do
        conversation = inbox.conversations.first
        conversation.update_labels('resolved')

        result = conversation_finder.perform
        expect(result[:conversations].length).to be 1
      end
    end

    context 'with pagination' do
      let(:params) { { status: 'open', assignee_type: 'me', page: 1 } }

      it 'returns paginated conversations' do
        create_list(:conversation, 50, account: account, inbox: inbox, assignee: user_1)
        result = conversation_finder.perform
        expect(result[:conversations].length).to be 25
      end
    end
  end
end
