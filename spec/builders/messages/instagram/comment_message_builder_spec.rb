require 'rails_helper'

describe Messages::Instagram::CommentMessageBuilder do
  subject(:message_builder) { described_class.new(messaging, instagram_inbox).perform }

  before do
    stub_request(:post, /graph\.instagram\.com/)
    allow(Messages::Instagram::CommentActivityMessageBuilder).to receive(:new).and_return(double(perform: true))
  end

  let!(:messaging) { build(:incoming_comment_ig_message) }
  let!(:account) { create(:account) }
  let!(:instagram_channel) { create(:channel_instagram, account: account, instagram_id: 'chatwoot-app-user-id-1') }
  let!(:instagram_inbox) { create(:inbox, channel: instagram_channel, account: account, greeting_enabled: false) }
  let!(:contact) { create(:contact, id: 'Sender-id-1', name: 'Jane Dae') }
  let!(:contact_inbox) { create(:contact_inbox, contact_id: contact.id, inbox_id: instagram_inbox.id, source_id: 'Sender-id-1') }
  let(:conversation) do
    create(:conversation, account_id: account.id, inbox_id: instagram_inbox.id, contact_id: contact.id)
  end

  describe '#perform' do
    context 'when the inbox requires reauthorization' do
      before do
        allow(instagram_inbox.channel).to receive(:reauthorization_required?).and_return(true)
      end

      it 'does not create message' do
        message_builder
        expect(Message.count).to eq(0)
        expect(Conversation.count).to eq(0)
      end
    end

    context 'when new message is received' do
      it 'creates a new message' do
        message_builder
        expect(Message.count).to eq(1)
        expect(Message.last.content).to eq(messaging[:text])
        expect(Message.last.source_id).to eq(messaging[:id])
        expect(Message.last.message_type).to eq('incoming')
      end
    end

    context 'when message already exists' do
      before do
        create(:message, source_id: messaging[:id], message_type: :incoming, inbox_id: instagram_inbox.id)
      end

      it 'does not create a new message' do
        expect { message_builder }.not_to change(Message, :count)
      end
    end

    context 'when lock to single conversation is disabled' do
      before do
        instagram_inbox.update!(lock_to_single_conversation: false)
      end

      it 'creates a new conversation if existing conversation is not present' do
        initial_count = Conversation.count
        message_builder

        expect(instagram_inbox.conversations.count).to eq(1)
        expect(Conversation.count).to eq(initial_count + 1)
      end

      it 'will not create a new conversation if last conversation is not resolved' do
        existing_conversation = create(:conversation, account_id: account.id, inbox_id: instagram_inbox.id,
                                                      contact_id: contact.id, status: :open)
        message_builder

        expect(instagram_inbox.conversations.last.id).to eq(existing_conversation.id)
      end

      it 'creates a new conversation if last conversation is resolved' do
        existing_conversation = create(:conversation, account_id: account.id, inbox_id: instagram_inbox.id,
                                                      contact_id: contact.id, status: :resolved)

        initial_count = Conversation.count
        message_builder

        expect(instagram_inbox.conversations.last.id).not_to eq(existing_conversation.id)
        expect(Conversation.count).to eq(initial_count + 1)
      end
    end

    context 'when lock to single conversation is enabled' do
      before do
        instagram_inbox.update!(lock_to_single_conversation: true)
      end

      it 'creates a new conversation if existing conversation is not present' do
        initial_count = Conversation.count
        message_builder

        expect(instagram_inbox.conversations.count).to eq(1)
        expect(Conversation.count).to eq(initial_count + 1)
      end

      it 'reopens last conversation if last conversation is resolved' do
        existing_conversation = create(:conversation, account_id: account.id, inbox_id: instagram_inbox.id,
                                                      contact_id: contact.id, status: :resolved)

        initial_count = Conversation.count
        message_builder

        expect(instagram_inbox.conversations.last.id).to eq(existing_conversation.id)
        expect(Conversation.count).to eq(initial_count)
      end
    end
  end
end
