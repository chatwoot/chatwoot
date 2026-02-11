require 'rails_helper'

RSpec.describe Mailbox::ConversationFinderStrategies::NewConversationStrategy do
  let(:account) { create(:account) }
  let(:email_channel) { create(:channel_email, account: account) }
  let(:mail) { Mail.new }

  before do
    mail.to = [email_channel.email]
    mail.from = 'sender@example.com'
    mail.subject = 'Test Subject'
    mail.message_id = '<test@example.com>'
  end

  describe '#find' do
    context 'when channel is found' do
      context 'with new contact' do
        it 'builds a new conversation with new contact' do
          strategy = described_class.new(mail)

          expect do
            conversation = strategy.find
            expect(conversation).to be_a(Conversation)
            expect(conversation.new_record?).to be(true) # Not persisted yet
            expect(conversation.inbox).to eq(email_channel.inbox)
            expect(conversation.account).to eq(account)
          end.to not_change(Conversation, :count) # No conversation created yet
            .and change(Contact, :count).by(1) # Contact is created
                                        .and change(ContactInbox, :count).by(1)
        end

        it 'sets conversation attributes correctly' do
          strategy = described_class.new(mail)
          conversation = strategy.find

          expect(conversation.additional_attributes['source']).to eq('email')
          expect(conversation.additional_attributes['mail_subject']).to eq('Test Subject')
          expect(conversation.additional_attributes['initiated_at']).to have_key('timestamp')
        end

        it 'sets contact attributes correctly' do
          strategy = described_class.new(mail)
          conversation = strategy.find

          expect(conversation.contact.email).to eq('sender@example.com')
          expect(conversation.contact.name).to eq('sender')
        end
      end

      context 'with existing contact' do
        let!(:existing_contact) { create(:contact, email: 'sender@example.com', account: account) }

        before do
          create(:contact_inbox, contact: existing_contact, inbox: email_channel.inbox)
        end

        it 'builds conversation with existing contact' do
          strategy = described_class.new(mail)

          expect do
            conversation = strategy.find
            expect(conversation).to be_a(Conversation)
            expect(conversation.new_record?).to be(true) # Not persisted yet
            expect(conversation.contact).to eq(existing_contact)
          end.to not_change(Conversation, :count) # No conversation created yet
            .and not_change(Contact, :count)
            .and not_change(ContactInbox, :count)
        end
      end

      context 'when mail has In-Reply-To header' do
        before do
          mail['In-Reply-To'] = '<previous-message@example.com>'
        end

        it 'stores in_reply_to in additional_attributes' do
          strategy = described_class.new(mail)
          conversation = strategy.find

          expect(conversation.additional_attributes['in_reply_to']).to eq('<previous-message@example.com>')
        end
      end

      context 'when mail is auto reply' do
        before do
          mail['X-Autoreply'] = 'yes'
        end

        it 'marks conversation as auto_reply' do
          strategy = described_class.new(mail)
          conversation = strategy.find

          expect(conversation.additional_attributes['auto_reply']).to be true
        end
      end

      context 'when sender has name in From header' do
        before do
          mail.from = 'John Doe <john@example.com>'
        end

        it 'uses sender name from mail' do
          strategy = described_class.new(mail)
          conversation = strategy.find

          expect(conversation.contact.name).to eq('John Doe')
        end
      end
    end

    context 'when channel is not found' do
      before do
        mail.to = ['nonexistent@example.com']
      end

      it 'returns nil' do
        strategy = described_class.new(mail)

        expect do
          result = strategy.find
          expect(result).to be_nil
        end.not_to change(Conversation, :count)
      end
    end

    context 'when contact creation fails' do
      before do
        builder = instance_double(ContactInboxWithContactBuilder)
        allow(ContactInboxWithContactBuilder).to receive(:new).and_return(builder)
        allow(builder).to receive(:perform).and_raise(ActiveRecord::RecordInvalid)
      end

      it 'rolls back the transaction' do
        strategy = described_class.new(mail)

        expect do
          strategy.find
        end.to raise_error(ActiveRecord::RecordInvalid)
          .and not_change(Conversation, :count)
          .and not_change(Contact, :count)
          .and not_change(ContactInbox, :count)
      end
    end

    context 'when conversation creation fails' do
      before do
        # Make conversation build fail with invalid attributes
        allow(Conversation).to receive(:new).and_return(Conversation.new)
      end

      it 'returns invalid conversation object' do
        strategy = described_class.new(mail)

        conversation = strategy.find
        expect(conversation).to be_a(Conversation)
        expect(conversation.new_record?).to be(true)
        expect(conversation.valid?).to be(false)
      end
    end
  end
end
