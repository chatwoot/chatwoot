# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InternalChat::Message do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:channel).class_name('InternalChat::Channel') }
    it { is_expected.to belong_to(:sender).class_name('User').optional }
    it { is_expected.to belong_to(:parent).class_name('InternalChat::Message').optional }
    it { is_expected.to have_many(:replies).class_name('InternalChat::Message').dependent(:destroy) }
    it { is_expected.to have_many(:attachments).class_name('InternalChat::MessageAttachment').dependent(:destroy) }
    it { is_expected.to have_many(:reactions).class_name('InternalChat::Reaction').dependent(:destroy) }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:content_type).with_values(text: 0, poll: 1, system: 2) }
  end

  describe 'validations' do
    describe 'content presence' do
      it 'requires content when there are no attachments' do
        message = build(:internal_chat_message, content: nil)
        expect(message).not_to be_valid
        expect(message.errors[:content]).to include("can't be blank")
      end
    end

    describe 'content length' do
      it 'is valid when content is within limit' do
        message = build(:internal_chat_message, content: 'a' * 150_000)
        expect(message).to be_valid
      end

      it 'is invalid when content exceeds maximum length' do
        message = build(:internal_chat_message, content: 'a' * 150_001)
        expect(message).not_to be_valid
        expect(message.errors[:content]).to include('is too long (maximum is 150000 characters)')
      end
    end
  end

  describe 'scopes' do
    let(:account) { create(:account) }
    let(:channel) { create(:internal_chat_channel, account: account) }
    let(:sender) { create(:user) }
    let!(:older_message) { create(:internal_chat_message, channel: channel, account: account, sender: sender, created_at: 2.hours.ago) }
    let!(:newer_message) { create(:internal_chat_message, channel: channel, account: account, sender: sender, created_at: 1.hour.ago) }

    describe '.ordered' do
      it 'returns messages in ascending order of created_at' do
        expect(channel.messages.ordered).to eq([older_message, newer_message])
      end
    end

    describe '.recent' do
      it 'returns messages in descending order of created_at' do
        expect(channel.messages.recent).to eq([newer_message, older_message])
      end
    end
  end

  describe '#edited?' do
    let(:message) { create(:internal_chat_message) }

    it 'returns false when content_attributes has no edited_at' do
      expect(message.edited?).to be false
    end

    it 'returns false when content_attributes is nil' do
      message.content_attributes = nil
      expect(message.edited?).to be false
    end

    it 'returns true when content_attributes contains edited_at' do
      message.content_attributes = { 'edited_at' => Time.current.iso8601 }
      expect(message.edited?).to be true
    end
  end

  describe '#thread?' do
    it 'returns true when message has a parent' do
      parent = create(:internal_chat_message)
      reply = create(:internal_chat_message, parent: parent, account: parent.account, channel: parent.channel)
      expect(reply.thread?).to be true
    end

    it 'returns false when message has no parent' do
      message = create(:internal_chat_message)
      expect(message.thread?).to be false
    end
  end

  describe '#thread_replies_count' do
    let(:parent) { create(:internal_chat_message) }

    it 'returns 0 when there are no replies' do
      expect(parent.thread_replies_count).to eq(0)
    end

    it 'returns the number of replies' do
      create(:internal_chat_message, parent: parent, account: parent.account, channel: parent.channel, sender: parent.sender)
      create(:internal_chat_message, parent: parent, account: parent.account, channel: parent.channel, sender: parent.sender)

      expect(parent.thread_replies_count).to eq(2)
    end
  end

  describe 'callbacks' do
    describe '#update_channel_activity' do
      it 'updates the channel last_activity_at after message creation' do
        channel = create(:internal_chat_channel, last_activity_at: 1.day.ago)

        freeze_time do
          message = create(:internal_chat_message, channel: channel, account: channel.account)
          channel.reload
          expect(channel.last_activity_at).to be_within(1.second).of(message.created_at)
        end
      end
    end
  end

  describe 'counter_cache' do
    it 'increments messages_count on channel when a message is created' do
      channel = create(:internal_chat_channel)
      expect { create(:internal_chat_message, channel: channel, account: channel.account) }
        .to change { channel.reload.messages_count }.by(1)
    end
  end

  describe '#push_event_data' do
    it 'exposes the message payload used as a notification secondary actor' do
      sender = create(:user)
      message = create(:internal_chat_message, sender: sender, content: 'hello')

      expect(message.push_event_data).to eq(
        id: message.id,
        content: 'hello',
        content_type: 'text',
        internal_chat_channel_id: message.internal_chat_channel_id,
        sender: sender.push_event_data
      )
    end

    it 'exposes a nil sender for messages without a sender' do
      message = create(:internal_chat_message, sender: nil, content: 'system note')

      expect(message.push_event_data[:sender]).to be_nil
    end
  end
end
