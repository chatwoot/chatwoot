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
  let!(:portal) { create(:portal, account: account) }
  let(:article) do
    create(:article, title: 'Harry Potter Magic Guide', content: 'Learn about wizardry', account: account, portal: portal, author: user,
                     status: 'published')
  end

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
        expect(search.perform.keys).to match_array(%i[contacts messages conversations articles])
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

      it 'returns articles for articles' do
        search_type = 'Article'
        search = described_class.new(current_user: user, current_account: account, params: params, search_type: search_type)
        expect(search.perform.keys).to match_array(%i[articles])
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
          allow(account).to receive(:feature_enabled?).and_call_original
          allow(account).to receive(:feature_enabled?).with('search_with_gin').and_return(false)
          search_service = described_class.new(current_user: user, current_account: account, params: params, search_type: search_type)

          expect(search_service).to receive(:filter_messages_with_like).and_call_original
          expect(search_service).not_to receive(:filter_messages_with_gin)

          search_service.perform
        end

        it 'uses GIN search when search_with_gin feature is enabled' do
          allow(account).to receive(:feature_enabled?).and_call_original
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
          allow(account).to receive(:feature_enabled?).and_call_original
          allow(account).to receive(:feature_enabled?).with('search_with_gin').and_return(true)
          gin_search = described_class.new(current_user: user, current_account: account, params: params, search_type: search_type)
          gin_results = gin_search.perform[:messages].map(&:id)

          # Test with LIKE search
          allow(account).to receive(:feature_enabled?).and_call_original
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

    context 'when article search' do
      it 'returns matching articles' do
        article2 = create(:article, title: 'Spellcasting Guide',
                                    account: account, portal: portal, author: user, status: 'published')
        article3 = create(:article, title: 'Spellcasting Manual',
                                    account: account, portal: portal, author: user, status: 'published')

        params = { q: 'Spellcasting' }
        search = described_class.new(current_user: user, current_account: account, params: params, search_type: 'Article')
        results = search.perform[:articles]

        expect(results.length).to eq(2)
        expect(results.map(&:id)).to contain_exactly(article2.id, article3.id)
      end

      it 'returns paginated results' do
        # Create many articles to test pagination
        16.times do |i|
          create(:article, title: "Magic Article #{i}", account: account, portal: portal, author: user, status: 'published')
        end

        params = { q: 'Magic', page: 1 }
        search = described_class.new(current_user: user, current_account: account, params: params, search_type: 'Article')
        results = search.perform[:articles]

        expect(results.length).to eq(15) # Default per_page is 15
      end
    end
  end

  describe '#message_base_query' do
    let(:params) { { q: 'test' } }
    let(:search_type) { 'Message' }

    context 'when user is admin' do
      let(:admin_user) { create(:user) }
      let(:admin_search) do
        create(:account_user, account: account, user: admin_user, role: 'administrator')
        described_class.new(current_user: admin_user, current_account: account, params: params, search_type: search_type)
      end

      it 'does not filter by inbox_id' do
        # Testing the private method itself seems like the best way to ensure
        # that the inboxes are not added to the search query
        base_query = admin_search.send(:message_base_query)

        # Should only have the time filter, not inbox filter
        expect(base_query.to_sql).to include('created_at >= ')
        expect(base_query.to_sql).not_to include('inbox_id')
      end
    end

    context 'when user is not admin' do
      before do
        account_user = account.account_users.find_or_create_by(user: user)
        account_user.update!(role: 'agent')
      end

      it 'filters by accessible inbox_id when user has limited access' do
        # Create an additional inbox that user is NOT assigned to
        create(:inbox, account: account)

        base_query = search.send(:message_base_query)

        # Should have both time and inbox filters
        expect(base_query.to_sql).to include('created_at >= ')
        expect(base_query.to_sql).to include('inbox_id')
      end

      context 'when user has access to all inboxes' do
        before do
          # Create additional inbox and assign user to all inboxes
          other_inbox = create(:inbox, account: account)
          create(:inbox_member, user: user, inbox: other_inbox)
        end

        it 'skips inbox filtering as optimization' do
          base_query = search.send(:message_base_query)

          # Should only have the time filter, not inbox filter
          expect(base_query.to_sql).to include('created_at >= ')
          expect(base_query.to_sql).not_to include('inbox_id')
        end
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

  describe '#advanced_search with filters', if: Message.respond_to?(:search) do
    let(:params) { { q: 'test' } }
    let(:search_type) { 'Message' }

    before do
      allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(true)
      allow(account).to receive(:feature_enabled?).and_call_original
      allow(account).to receive(:feature_enabled?).with('advanced_search').and_return(true)
      allow(Message).to receive(:search).and_return([])
    end

    context 'when advanced_search feature flag is disabled' do
      it 'ignores filters and falls back to standard search' do
        allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(false)
        contact = create(:contact, account: account)
        inbox2 = create(:inbox, account: account)

        params = { q: 'test', from: "contact:#{contact.id}", inbox_id: inbox2.id, since: 3.days.ago.to_i }
        search_service = described_class.new(current_user: user, current_account: account, params: params, search_type: search_type)

        expect(search_service).not_to receive(:advanced_search)
        search_service.perform
      end
    end

    context 'when filtering by from parameter' do
      let(:contact) { create(:contact, account: account) }
      let(:agent) { create(:user, account: account) }

      it 'filters messages from specific contact' do
        params = { q: 'test', from: "contact:#{contact.id}" }
        search_service = described_class.new(current_user: user, current_account: account, params: params, search_type: search_type)

        expect(Message).to receive(:search).with(
          'test',
          hash_including(
            where: hash_including(
              sender_type: 'Contact',
              sender_id: contact.id
            )
          )
        ).and_return([])

        search_service.perform
      end

      it 'filters messages from specific agent' do
        params = { q: 'test', from: "agent:#{agent.id}" }
        search_service = described_class.new(current_user: user, current_account: account, params: params, search_type: search_type)

        expect(Message).to receive(:search).with(
          'test',
          hash_including(
            where: hash_including(
              sender_type: 'User',
              sender_id: agent.id
            )
          )
        ).and_return([])

        search_service.perform
      end

      it 'ignores invalid from parameter format' do
        params = { q: 'test', from: 'invalid:format' }
        search_service = described_class.new(current_user: user, current_account: account, params: params, search_type: search_type)

        expect(Message).to receive(:search).with(
          'test',
          hash_including(
            where: hash_not_including(:sender_type, :sender_id)
          )
        ).and_return([])

        search_service.perform
      end
    end

    context 'when filtering by time range' do
      it 'defaults to 90 days ago when no since parameter is provided' do
        params = { q: 'test' }
        search_service = described_class.new(current_user: user, current_account: account, params: params, search_type: search_type)

        expect(Message).to receive(:search).with(
          'test',
          hash_including(
            where: hash_including(
              created_at: hash_including(gte: be_within(1.second).of(Limits::MESSAGE_SEARCH_TIME_RANGE_LIMIT_DAYS.days.ago))
            )
          )
        ).and_return([])

        search_service.perform
      end

      it 'raises error when since timestamp exceeds 90 day limit' do
        since_timestamp = (Limits::MESSAGE_SEARCH_TIME_RANGE_LIMIT_DAYS * 2).days.ago.to_i
        params = { q: 'test', since: since_timestamp }
        search_service = described_class.new(current_user: user, current_account: account, params: params, search_type: search_type)

        expect do
          search_service.perform
        end.to raise_error(ArgumentError, /Search is limited to the last #{Limits::MESSAGE_SEARCH_TIME_RANGE_LIMIT_DAYS} days/o)
      end

      it 'filters messages since timestamp when within 90 day limit' do
        since_timestamp = 3.days.ago.to_i
        params = { q: 'test', since: since_timestamp }
        search_service = described_class.new(current_user: user, current_account: account, params: params, search_type: search_type)

        expect(Message).to receive(:search).with(
          'test',
          hash_including(
            where: hash_including(
              created_at: hash_including(gte: Time.zone.at(since_timestamp))
            )
          )
        ).and_return([])

        search_service.perform
      end

      it 'filters messages until timestamp' do
        until_timestamp = 5.days.ago.to_i
        params = { q: 'test', until: until_timestamp }
        search_service = described_class.new(current_user: user, current_account: account, params: params, search_type: search_type)

        expect(Message).to receive(:search).with(
          'test',
          hash_including(
            where: hash_including(
              created_at: hash_including(lte: Time.zone.at(until_timestamp))
            )
          )
        ).and_return([])

        search_service.perform
      end

      it 'filters messages within time range' do
        since_timestamp = 5.days.ago.to_i
        until_timestamp = 12.hours.ago.to_i
        params = { q: 'test', since: since_timestamp, until: until_timestamp }
        search_service = described_class.new(current_user: user, current_account: account, params: params, search_type: search_type)

        expect(Message).to receive(:search).with(
          'test',
          hash_including(
            where: hash_including(
              created_at: hash_including(
                gte: Time.zone.at(since_timestamp),
                lte: Time.zone.at(until_timestamp)
              )
            )
          )
        ).and_return([])

        search_service.perform
      end
    end

    context 'when filtering by inbox_id' do
      let!(:inbox2) { create(:inbox, account: account) }

      before do
        create(:inbox_member, user: user, inbox: inbox2)
      end

      it 'filters messages from specific inbox' do
        params = { q: 'test', inbox_id: inbox2.id }
        search_service = described_class.new(current_user: user, current_account: account, params: params, search_type: search_type)

        expect(Message).to receive(:search).with(
          'test',
          hash_including(
            where: hash_including(inbox_id: inbox2.id)
          )
        ).and_return([])

        search_service.perform
      end

      it 'ignores inbox filter when user lacks access' do
        restricted_inbox = create(:inbox, account: account)
        params = { q: 'test', inbox_id: restricted_inbox.id }
        search_service = described_class.new(current_user: user, current_account: account, params: params, search_type: search_type)

        expect(Message).to receive(:search).with(
          'test',
          hash_including(
            where: hash_not_including(inbox_id: restricted_inbox.id)
          )
        ).and_return([])

        search_service.perform
      end
    end

    context 'when combining multiple filters' do
      it 'applies all filters together' do
        test_contact = create(:contact, account: account)
        test_inbox = create(:inbox, account: account)
        create(:inbox_member, user: user, inbox: test_inbox)

        since_timestamp = 3.days.ago.to_i
        params = { q: 'test', from: "contact:#{test_contact.id}", inbox_id: test_inbox.id, since: since_timestamp }
        search_service = described_class.new(current_user: user, current_account: account, params: params, search_type: search_type)

        expect(Message).to receive(:search).with(
          'test',
          hash_including(
            where: hash_including(
              sender_type: 'Contact',
              sender_id: test_contact.id,
              inbox_id: test_inbox.id,
              created_at: hash_including(gte: Time.zone.at(since_timestamp))
            )
          )
        ).and_return([])

        search_service.perform
      end
    end
  end
end
