require 'rails_helper'

describe ::SearchService do
  subject(:search) { described_class.new(current_user: user, current_account: account, params: params, search_type: search_type) }

  let(:search_type) { 'all' }
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account, enable_auto_assignment: false) }
  let(:harry) { create(:contact, name: 'Harry Potter', account_id: account.id) }

  before do
    create(:inbox_member, user: user, inbox: inbox)
    create(:conversation, contact: harry, inbox: inbox, account: account)
    create(:message, account: account, inbox: inbox, content: 'Harry Potter is a wizard')
    Current.account = account
  end

  after do
    Current.account = nil
  end

  describe '#perform' do
    context 'when search types' do
      let(:params) { { q: 'Potter' } }

      it 'returns all for all' do
        search_type = 'all'
        search = described_class.new(current_user: user, current_account: account, params: params, search_type: search_type)
        expect(search.perform.keys).to match_array(%i[contacts messages conversations])
      end

      it 'returns contacts for contacts' do
        search_type = 'Contact'
        search = described_class.new(current_user: user, current_account: account, params: params, search_type: search_type)
        expect(search.perform.keys).to match_array(%i[contacts])
      end

      it 'returns messages for messages' do
        search_type = 'Message'
        search = described_class.new(current_user: user, current_account: account, params: params, search_type: search_type)
        expect(search.perform.keys).to match_array(%i[messages])
      end

      it 'returns conversations for conversations' do
        search_type = 'Conversation'
        search = described_class.new(current_user: user, current_account: account, params: params, search_type: search_type)
        expect(search.perform.keys).to match_array(%i[conversations])
      end
    end

    context 'when contact search' do
      it 'searches across name, email, phone_number and identifier' do
        # random contact
        create(:contact, account_id: account.id)
        harry2 = create(:contact, email: 'HarryPotter@test.com', account_id: account.id)
        harry3 = create(:contact, identifier: 'Potter123', account_id: account.id)

        params = { q: 'Potter' }
        search = described_class.new(current_user: user, current_account: account, params: params, search_type: 'Contact')
        expect(search.perform[:contacts].map(&:id)).to match_array([harry.id, harry2.id, harry3.id])
      end
    end

    context 'when message search' do
      it 'searches across message content' do
        # random messages in another inbox
        create(:message, account: account, inbox: create(:inbox, account: account), content: 'Harry Potter is a wizard')
        create(:message, content: 'Harry Potter is a wizard')
        message2 = create(:message, account: account, inbox: inbox, content: 'harry is cool')
        params = { q: 'Harry' }
        search = described_class.new(current_user: user, current_account: account, params: params, search_type: 'Message')
        expect(search.perform[:messages].map(&:id)).to match_array([Message.first.id, message2.id])
      end
    end

    context 'when conversation search' do
      it 'searches across conversations using contact information' do
        # random messages in another inbox
        random = create(:contact, account_id: account.id)
        create(:conversation, contact: random, inbox: inbox, account: account)
        params = { q: 'Harry' }
        search = described_class.new(current_user: user, current_account: account, params: params, search_type: 'Conversation')
        expect(search.perform[:conversations].map(&:id)).to match_array([Conversation.first.id])
      end

      it 'searches across conversations with display id' do
        random = create(:contact, account_id: account.id, name: 'random', email: 'random@random.test', identifier: 'random')
        new_converstion = create(:conversation, contact: random, inbox: inbox, account: account)
        params = { q: new_converstion.display_id }
        search = described_class.new(current_user: user, current_account: account, params: params, search_type: 'Conversation')
        expect(search.perform[:conversations].map(&:id)).to match_array([new_converstion.id])
      end
    end
  end
end
