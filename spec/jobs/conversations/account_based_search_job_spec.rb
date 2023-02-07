require 'rails_helper'

describe ::Conversations::AccountBasedSearchJob, type: :job do
  let!(:account) { create(:account) }
  let!(:user_1) { create(:user, account: account) }
  let!(:user_2) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account, enable_auto_assignment: false) }

  before do
    create(:inbox_member, user: user_1, inbox: inbox)
    create(:inbox_member, user: user_2, inbox: inbox)

    create(:contact, name: '1223', account_id: account.id)
    create(:contact, name: 'Lily Potter', account_id: account.id)
    contact_2 = create(:contact, name: 'Harry Potter', account_id: account.id, email: 'harry@chatwoot.com')
    conversation_1 = create(:conversation, account: account, inbox: inbox, assignee: user_1, display_id: 1213)
    conversation_2 = create(:conversation, account: account, inbox: inbox, assignee: user_1, display_id: 1223)
    create(:conversation, account: account, inbox: inbox, assignee: user_1, status: 'resolved', display_id: 13, contact_id: contact_2.id)
    create(:conversation, account: account, inbox: inbox, assignee: user_2, display_id: 14)
    create(:conversation, account: account, inbox: inbox, display_id: 15)

    create(:message, conversation_id: conversation_1.id, account_id: account.id, content: 'Ask Lisa')
    create(:message, conversation_id: conversation_1.id, account_id: account.id, content: 'message_12')
    create(:message, conversation_id: conversation_1.id, account_id: account.id, content: 'message_13')

    create(:message, conversation_id: conversation_2.id, account_id: account.id, content: 'Pottery Barn order')
    create(:message, conversation_id: conversation_2.id, account_id: account.id, content: 'message_22')
    create(:message, conversation_id: conversation_2.id, account_id: account.id, content: 'message_23')
  end

  it 'enqueues the job' do
    expect { described_class.perform_later }.to have_enqueued_job(described_class).once.on_queue('async_database_migration')
  end

  describe 'when called' do
    let!(:account) { create(:account) }

    it 'Calls the account based search job' do
      PgSearch::Document.delete_all

      described_class.perform_now(account.id)

      total_records = Conversation.count + Contact.joins(:conversations).count + Message.count

      expect(PgSearch::Document.count).to eq(total_records)
    end
  end
end
