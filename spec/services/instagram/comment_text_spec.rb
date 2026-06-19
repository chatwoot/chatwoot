require 'rails_helper'

describe Instagram::CommentText do
  let!(:account) { create(:account) }
  let!(:channel) { create(:channel_instagram, account: account, instagram_id: 'connected-ig-account-id') }
  let(:inbox) { channel.inbox }

  def comment_value(overrides = {})
    {
      'from' => { 'id' => '999888777', 'username' => 'cliente_teste' },
      'media' => { 'id' => 'media-1', 'media_product_type' => 'FEED' },
      'id' => 'comment-1',
      'text' => 'Que produto lindo!'
    }.merge(overrides).with_indifferent_access
  end

  describe '#perform' do
    context 'with a new comment' do
      before { described_class.new(comment_value, channel).perform }

      it 'creates the commenter contact' do
        expect(inbox.contacts.count).to eq 1
        expect(inbox.contacts.last.additional_attributes['social_instagram_user_name']).to eq 'cliente_teste'
      end

      it 'creates a single comment conversation grouped by media' do
        conversation = inbox.conversations.last
        expect(inbox.conversations.count).to eq 1
        expect(conversation.additional_attributes['type']).to eq 'instagram_comment'
        expect(conversation.additional_attributes['instagram_media_id']).to eq 'media-1'
      end

      it 'creates an incoming comment message' do
        message = inbox.messages.last
        expect(message.message_type).to eq 'incoming'
        expect(message.content).to eq 'Que produto lindo!'
        expect(message.source_id).to eq 'comment-1'
        expect(message.content_attributes['type']).to eq 'instagram_comment'
        expect(message.content_attributes['instagram_comment_id']).to eq 'comment-1'
      end
    end

    it 'ignores comments authored by the connected account itself' do
      described_class.new(comment_value('from' => { 'id' => channel.instagram_id, 'username' => 'self' }), channel).perform

      expect(inbox.conversations.count).to eq 0
      expect(inbox.messages.count).to eq 0
    end

    it 'is idempotent for the same comment id' do
      2.times { described_class.new(comment_value, channel).perform }

      expect(inbox.messages.count).to eq 1
    end

    it 'groups multiple comments on the same media into one conversation' do
      described_class.new(comment_value('id' => 'c1', 'text' => 'primeiro'), channel).perform
      described_class.new(comment_value('id' => 'c2', 'text' => 'segundo'), channel).perform

      expect(inbox.conversations.count).to eq 1
      expect(inbox.messages.count).to eq 2
    end
  end

  describe 'routing via Webhooks::InstagramEventsJob' do
    let(:comment_entry) do
      [{ 'id' => channel.instagram_id, 'time' => 1,
         'changes' => [{ 'field' => 'comments', 'value' => comment_value }] }]
    end

    it 'routes comment change events to Instagram::CommentText' do
      expect(described_class).to receive(:new).with(kind_of(Hash), kind_of(Channel::Instagram)).and_call_original
      Webhooks::InstagramEventsJob.perform_now(comment_entry)
    end

    it 'does not treat a real comment change as a test event' do
      expect(Instagram::TestEventService).not_to receive(:new)
      Webhooks::InstagramEventsJob.perform_now(comment_entry)
    end

    it 'also handles entry-level comment payloads (field/value on the entry)' do
      entry_level = [{ 'id' => channel.instagram_id, 'time' => 1, 'field' => 'comments', 'value' => comment_value }]
      expect(described_class).to receive(:new).with(kind_of(Hash), kind_of(Channel::Instagram)).and_call_original
      Webhooks::InstagramEventsJob.perform_now(entry_level)
    end
  end
end
