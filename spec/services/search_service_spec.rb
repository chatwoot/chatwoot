require 'rails_helper'

describe SearchService do
  subject(:search) do
    described_class.new(current_user: user, current_account: account, current_account_user: user.account_users.find_by(account: account),
                        params: params, search_type: search_type)
  end

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
        search = described_class.new(current_user: user, current_account: account,
                                     current_account_user: user.account_users.find_by(account: account),
                                     params: params, search_type: search_type)
        expect(search.perform.keys).to match_array(%i[contacts messages conversations])
      end

      it 'returns contacts for contacts' do
        search_type = 'Contact'
        search = described_class.new(current_user: user, current_account: account,
                                     current_account_user: user.account_users.find_by(account: account),
                                     params: params, search_type: search_type)
        expect(search.perform.keys).to match_array(%i[contacts])
      end

      it 'returns messages for messages' do
        search_type = 'Message'
        search = described_class.new(current_user: user, current_account: account,
                                     current_account_user: user.account_users.find_by(account: account),
                                     params: params, search_type: search_type)
        expect(search.perform.keys).to match_array(%i[messages])
      end

      it 'returns conversations for conversations' do
        search_type = 'Conversation'
        search = described_class.new(current_user: user, current_account: account,
                                     current_account_user: user.account_users.find_by(account: account),
                                     params: params, search_type: search_type)
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
        search = described_class.new(current_user: user, current_account: account,
                                     current_account_user: user.account_users.find_by(account: account), params: params, search_type: 'Contact')
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
        search = described_class.new(current_user: user, current_account: account,
                                     current_account_user: user.account_users.find_by(account: account), params: params, search_type: 'Message')
        expect(search.perform[:messages].map(&:id)).to eq([message2.id, message.id])
      end

      context 'with different search methods' do
        let(:search_type) { 'Message' }

        it 'uses LIKE search for multi-word queries' do
          params = { q: 'Harry Potter' }
          search_service = described_class.new(current_user: user, current_account: account,
                                               current_account_user: user.account_users.find_by(account: account),
                                               params: params, search_type: search_type)

          expect(search_service).to receive(:filter_messages_with_like).and_call_original
          expect(search_service).not_to receive(:filter_messages_with_gin)

          search_service.perform
        end

        it 'uses GIN search for single-word queries' do
          params = { q: 'Harry' }
          search_service = described_class.new(current_user: user, current_account: account,
                                               current_account_user: user.account_users.find_by(account: account),
                                               params: params, search_type: search_type)

          expect(search_service).to receive(:filter_messages_with_gin).and_call_original
          expect(search_service).not_to receive(:filter_messages_with_like)

          search_service.perform
        end

        it 'returns same results for single word regardless of search method' do
          # Create test messages
          message3 = create(:message, account: account, inbox: inbox, content: 'Harry is a wizard apprentice')
          params = { q: 'Harry' }

          # Test with GIN search (single word)
          gin_search = described_class.new(current_user: user, current_account: account,
                                           current_account_user: user.account_users.find_by(account: account),
                                           params: params, search_type: search_type)
          allow(gin_search).to receive(:use_gin_search).and_return(true)
          gin_results = gin_search.perform[:messages].map(&:id)

          # Test with LIKE search (forcing LIKE for comparison)
          like_search = described_class.new(current_user: user, current_account: account,
                                            current_account_user: user.account_users.find_by(account: account),
                                            params: params, search_type: search_type)
          allow(like_search).to receive(:use_gin_search).and_return(false)
          like_results = like_search.perform[:messages].map(&:id)

          # Both search types should return the same messages
          expect(gin_results).to match_array(like_results)
          expect(gin_results).to include(message.id, message2.id, message3.id)
        end

        it 'handles empty search queries' do
          params = { q: '' }
          search_service = described_class.new(current_user: user, current_account: account,
                                               current_account_user: user.account_users.find_by(account: account),
                                               params: params, search_type: search_type)

          results = search_service.perform[:messages]
          expect(results).to be_a(ActiveRecord::Relation)
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
        search = described_class.new(current_user: user, current_account: account,
                                     current_account_user: user.account_users.find_by(account: account), params: params, search_type: 'Conversation')
        expect(search.perform[:conversations].map(&:id)).to eq([conv2.id, conversation.id])
      end

      it 'searches across conversations with display id' do
        random = create(:contact, account_id: account.id, name: 'random', email: 'random@random.test', identifier: 'random')
        new_converstion = create(:conversation, contact: random, inbox: inbox, account: account)
        params = { q: new_converstion.display_id }
        search = described_class.new(current_user: user, current_account: account,
                                     current_account_user: user.account_users.find_by(account: account), params: params, search_type: 'Conversation')
        expect(search.perform[:conversations].map(&:id)).to include new_converstion.id
      end
    end
  end

  describe '#use_gin_search' do
    it 'returns true for single-word queries' do
      params = { q: 'test' }
      search = described_class.new(current_user: user, current_account: account, current_account_user: user.account_users.find_by(account: account),
                                   params: params, search_type: 'Message')
      expect(search.send(:use_gin_search)).to be true
    end

    it 'returns false for multi-word queries' do
      params = { q: 'test query' }
      search = described_class.new(current_user: user, current_account: account, current_account_user: user.account_users.find_by(account: account),
                                   params: params, search_type: 'Message')
      expect(search.send(:use_gin_search)).to be false
    end

    it 'returns false for empty queries' do
      params = { q: '' }
      search = described_class.new(current_user: user, current_account: account, current_account_user: user.account_users.find_by(account: account),
                                   params: params, search_type: 'Message')
      expect(search.send(:use_gin_search)).to be false
    end

    it 'returns false for nil queries' do
      params = { q: nil }
      search = described_class.new(current_user: user, current_account: account, current_account_user: user.account_users.find_by(account: account),
                                   params: params, search_type: 'Message')
      expect(search.send(:use_gin_search)).to be false
    end
  end

  describe '#accessable_inbox_ids' do
    it 'returns inbox ids assigned to the user' do
      search = described_class.new(current_user: user, current_account: account, current_account_user: user.account_users.find_by(account: account),
                                   params: {}, search_type: 'Message')
      expect(search.send(:accessable_inbox_ids)).to eq([inbox.id])
    end
  end

  describe '#message_base_query' do
    it 'returns messages from the last 3 months' do
      old_message = create(:message, account: account, inbox: inbox, content: 'old message', created_at: 4.months.ago)
      recent_message = create(:message, account: account, inbox: inbox, content: 'recent message', created_at: 2.months.ago)

      search = described_class.new(current_user: user, current_account: account, current_account_user: user.account_users.find_by(account: account),
                                   params: {}, search_type: 'Message')
      base_query = search.send(:message_base_query)

      expect(base_query).to include(recent_message)
      expect(base_query).not_to include(old_message)
    end

    it 'filters by inbox_id for non-administrators' do
      other_inbox = create(:inbox, account: account)
      other_inbox_message = create(:message, account: account, inbox: other_inbox, content: 'other inbox message')

      search = described_class.new(current_user: user, current_account: account, current_account_user: user.account_users.find_by(account: account),
                                   params: {}, search_type: 'Message')
      base_query = search.send(:message_base_query)

      expect(base_query).not_to include(other_inbox_message)
    end

    it 'does not filter by inbox_id for administrators' do
      # Create a new user with administrator role
      admin_user = create(:user, account: account, role: :administrator)
      other_inbox = create(:inbox, account: account)
      other_inbox_message = create(:message, account: account, inbox: other_inbox, content: 'other inbox message')

      search = described_class.new(current_user: admin_user, current_account: account,
                                   current_account_user: admin_user.account_users.find_by(account: account), params: {}, search_type: 'Message')
      base_query = search.send(:message_base_query)

      expect(base_query).to include(other_inbox_message)
    end
  end
end
