require 'rails_helper'

describe ::TextSearch do
  subject(:text_search) { described_class.new(user_1, params) }

  let!(:account) { create(:account) }
  let!(:user_1) { create(:user, account: account) }
  let!(:user_2) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account, enable_auto_assignment: false) }

  before do
    create(:inbox_member, user: user_1, inbox: inbox)
    create(:inbox_member, user: user_2, inbox: inbox)

    create(:contact, name: '1223', account_id: account.id)
    create(:contact, name: 'Potter', account_id: account.id)
    contact_2 = create(:contact, name: 'Harry Potter', account_id: account.id)
    conversation_1 = create(:conversation, account: account, inbox: inbox, assignee: user_1, display_id: 121)
    conversation_2 = create(:conversation, account: account, inbox: inbox, assignee: user_1, display_id: 122)
    create(:conversation, account: account, inbox: inbox, assignee: user_1, status: 'resolved', display_id: 13, contact_id: contact_2.id)
    create(:conversation, account: account, inbox: inbox, assignee: user_2, display_id: 14)
    create(:conversation, account: account, inbox: inbox, display_id: 15)
    Current.account = account

    create(:message, conversation_id: conversation_1.id, account_id: account.id, content: 'Ask Lisa')
    create(:message, conversation_id: conversation_1.id, account_id: account.id, content: 'message_12')
    create(:message, conversation_id: conversation_1.id, account_id: account.id, content: 'message_13')

    create(:message, conversation_id: conversation_2.id, account_id: account.id, content: 'Pottery Barn order')
    create(:message, conversation_id: conversation_2.id, account_id: account.id, content: 'message_22')
    create(:message, conversation_id: conversation_2.id, account_id: account.id, content: 'message_23')
  end

  describe '#perform' do
    context 'with text search' do
      it 'filter conversations by number' do
        params = { q: '12' }
        result = described_class.new(user_1, params).perform
        expect(result[:conversations].length).to be 2
        expect(result[:contacts].length).to be 1
      end

      it 'filter conversations by string' do
        params = { q: 'pot' }
        result = described_class.new(user_1, params).perform
        expect(result[:messages].length).to be 1
        expect(result[:contacts].length).to be 2
      end
    end
  end
end
