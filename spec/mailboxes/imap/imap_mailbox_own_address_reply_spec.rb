require 'rails_helper'

# Somebody answering from the mailbox the inbox reads (the Gmail web UI of the same address)
# is the business replying, not the customer writing again. Stored as incoming, it put the
# human's words under the customer's name and had an AI agent on the inbox answer on top of
# the human, because for the agent the customer had just written.
RSpec.describe Imap::ImapMailbox do
  include ActionMailbox::TestHelper

  let(:channel) { create(:channel_email, :imap_email) }
  let(:inbox) { channel.inbox }
  let(:account) { inbox.account }
  let(:contact) { create(:contact, email: 'customer@example.com', account: account) }
  let!(:conversation) do
    contact_inbox = create(:contact_inbox, contact: contact, inbox: inbox)
    create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox)
  end
  let(:reply_subject) { 'Re: pedido' }

  before do
    create(:message, conversation: conversation, account: account, inbox: inbox, message_type: :incoming,
                     sender: contact, source_id: 'customer-1@example.com')
  end

  def deliver(**headers)
    mail = create_inbound_email_from_mail(to: 'customer@example.com', subject: reply_subject, body: 'Pode sim.', **headers).mail
    described_class.new.process(mail, channel)
  end

  it 'stores a threaded reply from the inbox address as outgoing, with no sender and its source id' do
    expect { deliver(from: channel.email, in_reply_to: 'customer-1@example.com', message_id: 'own-1@example.com') }
      .to change(conversation.messages, :count).by(1)

    reply = conversation.messages.find_by(source_id: 'own-1@example.com')
    expect(reply).to be_outgoing
    expect(reply.sender).to be_nil
    expect(reply.content_attributes.dig('email', 'from')).to eq([channel.email])
  end

  # The reply box takes the next reply's recipients from the latest email, and quotes an
  # outgoing one under the inbox's address read from `email.to`.
  it 'stores the recipients the way an outgoing email has them' do
    deliver(from: channel.email, cc: 'boss@example.com', in_reply_to: 'customer-1@example.com', message_id: 'own-7@example.com')

    attributes = conversation.messages.find_by(source_id: 'own-7@example.com').content_attributes
    expect(attributes).to include('to_emails' => ['customer@example.com'], 'cc_emails' => ['boss@example.com'])
    expect(attributes['email']).not_to have_key('to')
  end

  it 'counts as the human answer to a waiting conversation' do
    conversation.update!(waiting_since: 1.hour.ago)

    deliver(from: channel.email, in_reply_to: 'customer-1@example.com', message_id: 'own-6@example.com')

    expect(conversation.messages.find_by(source_id: 'own-6@example.com').content_attributes['external_echo']).to be(true)
    expect(conversation.reload.waiting_since).to be_nil
  end

  it 'does not take an automatic reply from the mailbox for a human answer' do
    conversation.update!(waiting_since: 1.hour.ago)

    deliver(from: channel.email, in_reply_to: 'customer-1@example.com', message_id: 'own-8@example.com', auto_submitted: 'auto-replied')

    expect(conversation.messages.find_by(source_id: 'own-8@example.com').content_attributes).not_to have_key('external_echo')
    expect(conversation.reload.waiting_since).to be_present
  end

  # Stored, it would be the latest email, and the reply box would address the next answer to the supplier.
  it 'leaves out a mail in the thread sent only to somebody else' do
    conversation.update!(waiting_since: 1.hour.ago)

    expect do
      deliver(from: channel.email, to: 'supplier@example.com', in_reply_to: 'customer-1@example.com', message_id: 'own-10@example.com')
    end.not_to change(Message, :count)
    expect(conversation.reload.waiting_since).to be_present
    expect(Imap::DeletedMessageTracker.new(inbox: inbox).deleted?('own-10@example.com')).to be(true)
  end

  # Liquid is for replies typed in Chatwoot; this mail already went out as written.
  it 'stores the text as sent, without rendering Liquid in it' do
    deliver(from: channel.email, in_reply_to: 'customer-1@example.com', message_id: 'own-9@example.com', body: 'Use {{ contact.name }} no modelo.')

    expect(conversation.messages.find_by(source_id: 'own-9@example.com').content).to include('{{ contact.name }}')
  end

  it 'reads the inbox address case-insensitively' do
    deliver(from: channel.email.upcase, in_reply_to: 'customer-1@example.com', message_id: 'own-2@example.com')

    expect(conversation.messages.find_by(source_id: 'own-2@example.com')).to be_outgoing
  end

  it 'threads by References when there is no In-Reply-To' do
    deliver(from: channel.email, references: '<customer-1@example.com>', message_id: 'own-3@example.com')

    expect(conversation.messages.find_by(source_id: 'own-3@example.com')).to be_outgoing
  end

  # The send path skips an outgoing message that already has a source id, which is the only
  # thing keeping the customer from getting the same reply twice.
  it 'does not send the reply again' do
    allow(ConversationReplyMailer).to receive(:with).and_call_original

    perform_enqueued_jobs(only: SendReplyJob) do
      deliver(from: channel.email, in_reply_to: 'customer-1@example.com', message_id: 'own-4@example.com')
    end

    expect(ConversationReplyMailer).not_to have_received(:with)
  end

  it 'opens nothing for mail from the inbox address that threads into no conversation' do
    expect do
      deliver(from: channel.email, in_reply_to: 'nowhere@example.com', message_id: 'own-5@example.com')
    end.to not_change(Conversation, :count).and(not_change(Contact, :count)).and(not_change(Message, :count))
  end

  # Nothing is stored for it, so without a record the fetch would pick it up on every sweep.
  it 'keeps the fetch from picking up again a mail with no thread headers' do
    deliver(from: channel.email, message_id: 'own-11@example.com')

    expect(Imap::DeletedMessageTracker.new(inbox: inbox).deleted?('own-11@example.com')).to be(true)
  end

  # The customer mail it answers may still be on its way in, for a few sweeps.
  it 'retries a mail citing a message Chatwoot does not have yet for a few sweeps, then leaves it' do
    tracker = Imap::DeletedMessageTracker.new(inbox: inbox)
    mail = create_inbound_email_from_mail(from: channel.email, to: 'customer@example.com', in_reply_to: 'not-yet@example.com',
                                          message_id: 'own-12@example.com', subject: reply_subject, body: 'Pode sim.').mail
    sweep = -> { described_class.new.process(mail, channel) }

    (ImapOwnAddressReply::THREAD_ATTEMPTS - 1).times { sweep.call }
    expect(tracker.deleted?('own-12@example.com')).to be(false)

    sweep.call
    expect(tracker.deleted?('own-12@example.com')).to be(true)
  end

  # Reply-To says where answers go, not who wrote the mail.
  it 'keeps mail from somebody else with the inbox as Reply-To incoming' do
    deliver(from: 'customer@example.com', reply_to: channel.email, in_reply_to: 'customer-1@example.com', message_id: 'cust-3@example.com')

    expect(conversation.messages.find_by(source_id: 'cust-3@example.com')).to be_incoming
  end

  it 'keeps a contact form sent to an alias with the inbox in Cc as the customer writing in' do
    deliver(from: channel.email, to: 'sales@example.com', cc: channel.email, reply_to: 'lead2@example.com', message_id: 'form-2@example.com')

    expect(Message.find_by(source_id: 'form-2@example.com')&.sender&.email).to eq('lead2@example.com')
  end

  it 'keeps a contact form sent through an alias of the inbox as the customer writing in' do
    deliver(from: channel.email, to: 'contato@example.com', reply_to: 'lead3@example.com', message_id: 'form-3@example.com')

    expect(Message.find_by(source_id: 'form-3@example.com')&.sender&.email).to eq('lead3@example.com')
  end

  # A contact form posts as the inbox, to the inbox, with the customer in Reply-To.
  it 'keeps a contact form sent by the inbox to itself as the customer writing in' do
    expect do
      deliver(from: channel.email, to: channel.email, reply_to: 'lead@example.com', message_id: 'form-1@example.com')
    end.to change(Conversation, :count).by(1)

    form = Message.find_by(source_id: 'form-1@example.com')
    expect(form).to be_incoming
    expect(form.sender.email).to eq('lead@example.com')
  end

  it 'keeps a customer reply that copies the inbox as incoming from the customer' do
    deliver(from: 'customer@example.com', cc: channel.email, in_reply_to: 'customer-1@example.com', message_id: 'cust-2@example.com')

    reply = conversation.messages.find_by(source_id: 'cust-2@example.com')
    expect(reply).to be_incoming
    expect(reply.sender).to eq(contact)
  end
end
