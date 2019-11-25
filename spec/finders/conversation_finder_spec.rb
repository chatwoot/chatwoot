require 'rails_helper'

describe ConversationFinder do
  let!(:account) { create(:account) }
  let!(:user_1) { create(:user, account: account) }
  let!(:user_2) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account) }
  # rubocop:disable RSpec/LetSetup
  let!(:inbox_member_1) { create(:inbox_member, user: user_1, inbox: inbox) }
  let!(:inbox_member_2) { create(:inbox_member, user: user_2, inbox: inbox) }
  let!(:conversation_1) { create(:complete_conversation, account: account, inbox: inbox, assignee: user_1) }
  let!(:conversation_2) { create(:complete_conversation, account: account, inbox: inbox, assignee: user_1) }
  let!(:conversation_3) { create(:complete_conversation, account: account, inbox: inbox, assignee: user_1, status: 'resolved') }
  let!(:conversation_4) { create(:complete_conversation, account: account, inbox: inbox, assignee: user_2) }
  # rubocop:enable RSpec/LetSetup

  describe 'Filtering' do
    context 'with status' do
      it 'filter conversations by status' do
        params = { status: 'open', assignee_type_id: 0 }

        finder = described_class.new(user_1, params)
        result = finder.perform

        expect(result[:conversations].count).to be 2
      end
    end

    context 'with assignee' do
      it 'filter conversations by status' do
        params = { assignee_type_id: 2 }

        finder = described_class.new(user_1, params)
        result = finder.perform

        expect(result[:conversations].count).to be 3
      end
    end
  end
end
