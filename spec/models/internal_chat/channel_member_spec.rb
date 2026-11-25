# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InternalChat::ChannelMember do
  # `cache_classes = false` in the test env lets Zeitwerk reload constants
  # between specs (controller specs commonly trigger this). After a reload,
  # the `described_class` captured when this file was loaded points at a stale
  # copy: record equality (`include` matchers) and shoulda's `class_name`
  # resolution both compare against the freshly-loaded class and fail.
  # Re-resolving the constant on every example keeps the reference fresh.
  let(:described_class) { InternalChat::ChannelMember } # rubocop:disable RSpec/DescribedClass

  describe 'associations' do
    it { is_expected.to belong_to(:channel).class_name('InternalChat::Channel') }
    it { is_expected.to belong_to(:user) }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:role).with_values(member: 0, admin: 1) }
  end

  describe 'validations' do
    describe 'uniqueness of user_id scoped to channel' do
      let!(:channel_member) { create(:internal_chat_channel_member) }

      it 'does not allow the same user to be added to the same channel twice' do
        duplicate = described_class.new(
          channel: channel_member.channel,
          user: channel_member.user,
          role: :member
        )
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:user_id]).to include('has already been taken')
      end

      it 'allows the same user in different channels' do
        other_channel = create(:internal_chat_channel, account: channel_member.channel.account)
        other_member = build(:internal_chat_channel_member, channel: other_channel, user: channel_member.user)
        expect(other_member).to be_valid
      end
    end
  end

  describe 'scopes' do
    let!(:regular_member) { create(:internal_chat_channel_member, muted: false, favorited: false) }
    let!(:muted_member) { create(:internal_chat_channel_member, :muted) }
    let!(:favorited_member) { create(:internal_chat_channel_member, :favorited) }

    describe '.not_muted' do
      it 'returns members that are not muted' do
        expect(described_class.not_muted).to include(regular_member, favorited_member)
        expect(described_class.not_muted).not_to include(muted_member)
      end
    end

    describe '.muted' do
      it 'returns only muted members' do
        expect(described_class.muted).to include(muted_member)
        expect(described_class.muted).not_to include(regular_member, favorited_member)
      end
    end

    describe '.favorited' do
      it 'returns only favorited members' do
        expect(described_class.favorited).to include(favorited_member)
        expect(described_class.favorited).not_to include(regular_member, muted_member)
      end
    end
  end

  describe '#unread_messages_count' do
    let(:account) { create(:account) }
    let(:channel) { create(:internal_chat_channel, account: account) }
    let(:sender) { create(:user) }
    let(:member) { create(:internal_chat_channel_member, channel: channel) }

    it 'counts all messages from other users when last_read_at is blank' do
      create(:internal_chat_message, channel: channel, account: account, sender: sender, created_at: 3.minutes.ago)
      create(:internal_chat_message, channel: channel, account: account, sender: sender, created_at: 1.minute.ago)

      member.update!(last_read_at: nil)
      expect(member.unread_messages_count).to eq(2)
    end

    it 'returns the count of messages created after last_read_at' do
      create(:internal_chat_message, channel: channel, account: account, sender: sender, created_at: 3.minutes.ago)
      create(:internal_chat_message, channel: channel, account: account, sender: sender, created_at: 1.minute.ago)

      member.update!(last_read_at: 2.minutes.ago)

      expect(member.unread_messages_count).to eq(1)
    end

    it 'returns 0 when all messages have been read' do
      create(:internal_chat_message, channel: channel, account: account, sender: sender, created_at: 5.minutes.ago)

      member.update!(last_read_at: Time.current)

      expect(member.unread_messages_count).to eq(0)
    end
  end
end
