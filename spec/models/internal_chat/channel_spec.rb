# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InternalChat::Channel do
  # Named rather than taken from `described_class`, which RSpec captured when this file
  # loaded: a reload later in the run replaces the class, and the old object's relations
  # no longer resolve to what the factories build. `ActiveRecord::Base#==` compares
  # `instance_of?(self.class)`, so the rows come back right and still fail to match.
  subject { InternalChat::Channel.new } # rubocop:disable RSpec/DescribedClass

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:category).class_name('InternalChat::Category').optional }
    it { is_expected.to belong_to(:created_by).class_name('User').optional }
    it { is_expected.to have_many(:channel_members).class_name('InternalChat::ChannelMember').dependent(:destroy) }
    it { is_expected.to have_many(:members).through(:channel_members).source(:user) }
    it { is_expected.to have_many(:messages).class_name('InternalChat::Message').dependent(:destroy) }
    it { is_expected.to have_many(:message_attachments).through(:messages).source(:attachments) }
  end

  describe 'enums' do
    it {
      expect(subject).to define_enum_for(:channel_type)
        .with_values(public_channel: 0, private_channel: 1, dm: 2)
        .with_prefix(:channel_type)
    }

    it { is_expected.to define_enum_for(:status).with_values(active: 0, archived: 1) }
  end

  describe 'validations' do
    describe 'name presence' do
      it 'requires name for public channels' do
        channel = build(:internal_chat_channel, name: nil, channel_type: :public_channel)
        expect(channel).not_to be_valid
        expect(channel.errors[:name]).to include("can't be blank")
      end

      it 'requires name for private channels' do
        channel = build(:internal_chat_channel, name: nil, channel_type: :private_channel)
        expect(channel).not_to be_valid
        expect(channel.errors[:name]).to include("can't be blank")
      end

      it 'does not require name for DM channels' do
        channel = build(:internal_chat_channel, :dm)
        expect(channel).to be_valid
      end
    end

    describe 'uuid uniqueness' do
      let!(:channel) { create(:internal_chat_channel) }

      it 'does not allow duplicate uuids' do
        duplicate = build(:internal_chat_channel, uuid: channel.uuid)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:uuid]).to include('has already been taken')
      end
    end
  end

  # rubocop:disable RSpec/DescribedClass -- see the note on `subject` above
  describe 'scopes' do
    let(:account) { create(:account) }
    let!(:active_public) { create(:internal_chat_channel, account: account, channel_type: :public_channel, status: :active) }
    let!(:active_private) { create(:internal_chat_channel, account: account, channel_type: :private_channel, status: :active) }
    let!(:active_dm) { create(:internal_chat_channel, :dm, account: account, status: :active) }
    let!(:archived_channel) { create(:internal_chat_channel, :archived, account: account) }

    describe '.active' do
      it 'returns only active channels' do
        expect(InternalChat::Channel.active).to include(active_public, active_private, active_dm)
        expect(InternalChat::Channel.active).not_to include(archived_channel)
      end
    end

    describe '.archived' do
      it 'returns only archived channels' do
        expect(InternalChat::Channel.archived).to include(archived_channel)
        expect(InternalChat::Channel.archived).not_to include(active_public, active_private, active_dm)
      end
    end

    describe '.text_channels' do
      it 'returns public and private channels but not DMs' do
        expect(InternalChat::Channel.text_channels).to include(active_public, active_private, archived_channel)
        expect(InternalChat::Channel.text_channels).not_to include(active_dm)
      end
    end

    describe '.direct_messages' do
      it 'returns only DM channels' do
        expect(InternalChat::Channel.direct_messages).to include(active_dm)
        expect(InternalChat::Channel.direct_messages).not_to include(active_public, active_private, archived_channel)
      end
    end
  end
  # rubocop:enable RSpec/DescribedClass

  describe '#dm?' do
    it 'returns true for DM channels' do
      channel = build(:internal_chat_channel, :dm)
      expect(channel.dm?).to be true
    end

    it 'returns false for public channels' do
      channel = build(:internal_chat_channel, :public_channel)
      expect(channel.dm?).to be false
    end

    it 'returns false for private channels' do
      channel = build(:internal_chat_channel, :private_channel)
      expect(channel.dm?).to be false
    end
  end

  describe 'callbacks' do
    describe '#set_last_activity_at' do
      it 'sets last_activity_at on create when not provided' do
        freeze_time do
          channel = create(:internal_chat_channel)
          expect(channel.last_activity_at).to be_within(1.second).of(Time.current)
        end
      end

      it 'does not overwrite last_activity_at if already set' do
        specific_time = 2.days.ago
        channel = create(:internal_chat_channel, last_activity_at: specific_time)
        expect(channel.last_activity_at).to be_within(1.second).of(specific_time)
      end
    end
  end

  describe '#push_event_data' do
    it 'exposes the fields needed to route and render a notification' do
      channel = create(:internal_chat_channel, :public_channel, name: 'general')

      expect(channel.push_event_data).to eq(
        id: channel.id,
        uuid: channel.uuid,
        name: 'general',
        channel_type: 'public_channel',
        account_id: channel.account_id,
        meta: {}
      )
    end

    it 'exposes the dm channel_type and nil name for direct messages' do
      channel = create(:internal_chat_channel, :dm)

      expect(channel.push_event_data).to include(channel_type: 'dm', name: nil)
    end
  end
end
