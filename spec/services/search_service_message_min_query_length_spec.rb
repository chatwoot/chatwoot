require 'rails_helper'

# MESSAGE_SEARCH_MIN_QUERY_LENGTH: below 3 characters the trigram index on messages.content cannot
# serve `ILIKE '%q%'`, so a short term walks every message of the account. The operator can set a
# minimum; unset or 0 keeps today's behavior.
describe SearchService do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account, enable_auto_assignment: false) }
  let!(:contact) { create(:contact, name: 'Maria Souza', phone_number: '+5516999990000', account: account) }
  let!(:conversation) { create(:conversation, contact: contact, inbox: inbox, account: account) }
  let!(:message) { create(:message, account: account, inbox: inbox, conversation: conversation, content: 'ligar no 16 amanha') }

  before do
    create(:inbox_member, user: user, inbox: inbox)
    Current.account = account
  end

  after do
    Current.account = nil
  end

  def search(query, search_type = 'Message')
    described_class.new(current_user: user, current_account: account, params: { q: query }, search_type: search_type).perform
  end

  def configure_minimum(value)
    InstallationConfig.where(name: 'MESSAGE_SEARCH_MIN_QUERY_LENGTH').first_or_create!(value: value, locked: false).update!(value: value)
  end

  context 'when the minimum is not configured' do
    it 'searches messages with a two character term' do
      expect(search('16')[:messages]).to contain_exactly(message)
    end
  end

  context 'when the minimum is 0' do
    before { configure_minimum(0) }

    it 'searches messages with a one character term' do
      expect(search('1')[:messages]).to contain_exactly(message)
    end
  end

  context 'when the minimum is 3' do
    before { configure_minimum(3) }

    it 'returns no messages for a shorter term without querying messages' do
      queries = []
      callback = ->(*, payload) { queries << payload[:sql] if payload[:sql].include?('"messages"') }
      result = ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { search('16')[:messages].to_a }

      expect(result).to be_empty
      expect(queries).to be_empty
    end

    it 'counts the term without surrounding spaces' do
      expect(search('  16  ')[:messages]).to be_empty
    end

    it 'searches messages with a term of exactly the minimum length' do
      expect(search('o 1')[:messages]).to contain_exactly(message)
    end

    it 'keeps contacts and conversations searching the short term in the global search' do
      result = search('16', 'all')

      expect(result[:messages]).to be_empty
      expect(result[:contacts]).to contain_exactly(contact)
      expect(result[:conversations]).to contain_exactly(conversation)
    end

    it 'does not apply to an empty term' do
      expect(search('')[:messages]).to include(message)
    end
  end
end
