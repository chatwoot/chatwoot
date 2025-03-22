require 'rails_helper'

describe SearchService do
  subject(:search) { described_class.new(current_user: user, current_account: account, params: params, search_type: search_type) }

  let(:search_type) { 'all' }
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account, enable_auto_assignment: false) }
  let!(:harry) { create(:contact, name: 'Harry Potter', email: 'test@test.com', account_id: account.id) }
  let!(:conversation) { create(:conversation, contact: harry, inbox: inbox, account: account) }
  let!(:message) { create(:message, account: account, inbox: inbox, content: 'Harry Potter is a wizard') }

  before do
    create(:inbox_member, user: user, inbox: inbox)
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
      it 'searches across name, email, phone_number and identifier and returns in the order of contact last_activity_at' do
        # random contact
        create(:contact, account_id: account.id)
        # unresolved contact -> no identifying info
        # will not appear in search results
        create(:contact, name: 'Harry Potter', account_id: account.id)
        harry2 = create(:contact, email: 'HarryPotter@test.com', account_id: account.id, last_activity_at: 2.days.ago)
        harry3 = create(:contact, identifier: 'Potter123', account_id: account.id, last_activity_at: 1.day.ago)
        harry4 = create(:contact, identifier: 'Potter1235', account_id: account.id, last_activity_at: 2.minutes.ago)

        params = { q: 'Potter ' }
        search = described_class.new(current_user: user, current_account: account, params: params, search_type: 'Contact')
        expect(search.perform[:contacts].map(&:id)).to eq([harry4.id, harry3.id, harry2.id, harry.id])
      end
    end

    context 'when message search' do
      let!(:message2) { create(:message, account: account, inbox: inbox, content: 'harry is cool') }

      it 'searches across message content and return in created_at desc' do
        # random messages in another account
        create(:message, content: 'Harry Potter is a wizard')
        # random messsage in inbox with out access
        create(:message, account: account, inbox: create(:inbox, account: account), content: 'Harry Potter is a wizard')
        params = { q: 'Harry' }
        search = described_class.new(current_user: user, current_account: account, params: params, search_type: 'Message')
        expect(search.perform[:messages].map(&:id)).to eq([message2.id, message.id])
      end

      context 'with feature flag for search type' do
        let(:params) { { q: 'Harry' } }
        let(:search_type) { 'Message' }

        it 'uses LIKE search when search_with_gin feature is disabled' do
          allow(account).to receive(:feature_enabled?).with('search_with_gin').and_return(false)
          search_service = described_class.new(current_user: user, current_account: account, params: params, search_type: search_type)

          expect(search_service).to receive(:filter_messages_with_like).and_call_original
          expect(search_service).not_to receive(:filter_messages_with_gin)

          search_service.perform
        end

        it 'uses GIN search when search_with_gin feature is enabled' do
          allow(account).to receive(:feature_enabled?).with('search_with_gin').and_return(true)
          search_service = described_class.new(current_user: user, current_account: account, params: params, search_type: search_type)

          expect(search_service).to receive(:filter_messages_with_gin).and_call_original
          expect(search_service).not_to receive(:filter_messages_with_like)

          search_service.perform
        end

        it 'returns same results regardless of search type' do
          # Create test messages
          message3 = create(:message, account: account, inbox: inbox, content: 'Harry is a wizard apprentice')

          # Test with GIN search
          allow(account).to receive(:feature_enabled?).with('search_with_gin').and_return(true)
          gin_search = described_class.new(current_user: user, current_account: account, params: params, search_type: search_type)
          gin_results = gin_search.perform[:messages].map(&:id)

          # Test with LIKE search
          allow(account).to receive(:feature_enabled?).with('search_with_gin').and_return(false)
          like_search = described_class.new(current_user: user, current_account: account, params: params, search_type: search_type)
          like_results = like_search.perform[:messages].map(&:id)

          # Both search types should return the same messages
          expect(gin_results).to match_array(like_results)
          expect(gin_results).to include(message.id, message2.id, message3.id)
        end
      end
    end

    context 'when conversation search' do
      it 'searches across conversations using contact information and order by created_at desc' do
        # random messages in another inbox
        random = create(:contact, account_id: account.id)
        create(:conversation, contact: random, inbox: inbox, account: account)
        conv2 = create(:conversation, contact: harry, inbox: inbox, account: account)
        params = { q: 'Harry' }
        search = described_class.new(current_user: user, current_account: account, params: params, search_type: 'Conversation')
        expect(search.perform[:conversations].map(&:id)).to eq([conv2.id, conversation.id])
      end

      it 'searches across conversations with display id' do
        random = create(:contact, account_id: account.id, name: 'random', email: 'random@random.test', identifier: 'random')
        new_converstion = create(:conversation, contact: random, inbox: inbox, account: account)
        params = { q: new_converstion.display_id }
        search = described_class.new(current_user: user, current_account: account, params: params, search_type: 'Conversation')
        expect(search.perform[:conversations].map(&:id)).to include new_converstion.id
      end
    end
  end

  describe '#use_gin_search' do
    let(:params) { { q: 'test' } }

    it 'checks if the account has the search_with_gin feature enabled' do
      expect(account).to receive(:feature_enabled?).with('search_with_gin')
      search.send(:use_gin_search)
    end

    it 'returns true when search_with_gin feature is enabled' do
      allow(account).to receive(:feature_enabled?).with('search_with_gin').and_return(true)
      expect(search.send(:use_gin_search)).to be true
    end

    it 'returns false when search_with_gin feature is disabled' do
      allow(account).to receive(:feature_enabled?).with('search_with_gin').and_return(false)
      expect(search.send(:use_gin_search)).to be false
    end
  end
end
