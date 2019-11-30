require 'rails_helper'

describe ::ConversationFinder do
  subject(:conversation_finder) { described_class.new(user_1, params) }

  let!(:account) { create(:account) }
  let!(:user_1) { create(:user, account: account) }
  let!(:user_2) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account) }

  before do
    create(:inbox_member, user: user_1, inbox: inbox)
    create(:inbox_member, user: user_2, inbox: inbox)
    create(:complete_conversation, account: account, inbox: inbox, assignee: user_1)
    create(:complete_conversation, account: account, inbox: inbox, assignee: user_1)
    create(:complete_conversation, account: account, inbox: inbox, assignee: user_1, status: 'resolved')
    create(:complete_conversation, account: account, inbox: inbox, assignee: user_2)
  end

  describe '#perform' do
    context 'with status' do
      let(:params) { { status: 'open', assignee_type_id: 0 } }

      it 'filter conversations by status' do
        result = conversation_finder.perform
        expect(result[:conversations].count).to be 2
      end
    end

    context 'with assignee' do
      let(:params) { { assignee_type_id: 2 } }

      it 'filter conversations by assignee' do
        result = conversation_finder.perform
        expect(result[:conversations].count).to be 3
      end
    end

    context 'with pagination' do
      let(:params) { { status: 'open', assignee_type_id: 0, page: 1 } }

      it 'returns paginated conversations' do
        create_list(:complete_conversation, 50, account: account, inbox: inbox, assignee: user_1)
        result = conversation_finder.perform
        expect(result[:conversations].count).to be 25
      end
    end
  end
end
