# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InternalChat::NotificationService do
  let(:account) { create(:account) }
  let(:sender) { create(:user, account: account, role: :agent) }

  describe '#perform' do
    context 'with a text channel message' do
      let(:channel) { create(:internal_chat_channel, :public_channel, account: account) }

      it 'does not create notifications for a regular (non-mention) message' do
        member = create(:user, account: account, role: :agent)
        create(:internal_chat_channel_member, channel: channel, user: sender)
        create(:internal_chat_channel_member, channel: channel, user: member)
        message = create(:internal_chat_message, account: account, channel: channel, sender: sender, content: 'Hello everyone')

        expect { described_class.new(message: message).perform }.not_to change(Notification, :count)
      end

      it 'creates a mention notification for a mentioned user' do
        mentioned_user = create(:user, account: account, role: :agent)
        create(:internal_chat_channel_member, channel: channel, user: sender)
        create(:internal_chat_channel_member, channel: channel, user: mentioned_user)
        message = create(
          :internal_chat_message, account: account, channel: channel, sender: sender,
                                  content: "Hey (mention://user/#{mentioned_user.id}/#{mentioned_user.name}) check this"
        )

        described_class.new(message: message).perform

        notification = Notification.find_by(user: mentioned_user, notification_type: 'internal_chat_mention')
        expect(notification).to have_attributes(primary_actor: channel, secondary_actor: message, account: account)
      end

      it 'does not create a notification for the sender' do
        create(:internal_chat_channel_member, channel: channel, user: sender)
        message = create(
          :internal_chat_message, account: account, channel: channel, sender: sender,
                                  content: "(mention://user/#{sender.id}/#{sender.name}) note to self"
        )

        described_class.new(message: message).perform

        expect(Notification.where(user: sender)).not_to exist
      end

      it 'creates mention notifications for @all when the sender is an admin' do
        admin_sender = create(:user, account: account, role: :administrator)
        member1 = create(:user, account: account, role: :agent)
        member2 = create(:user, account: account, role: :agent)
        create(:internal_chat_channel_member, channel: channel, user: admin_sender)
        create(:internal_chat_channel_member, channel: channel, user: member1)
        create(:internal_chat_channel_member, channel: channel, user: member2)
        message = create(:internal_chat_message, account: account, channel: channel, sender: admin_sender, content: '@all please review')

        described_class.new(message: message).perform

        expect(Notification.where(notification_type: 'internal_chat_mention', primary_actor: channel).pluck(:user_id))
          .to contain_exactly(member1.id, member2.id)
      end

      it 'does not create notifications for @all when the sender is a non-admin agent' do
        member = create(:user, account: account, role: :agent)
        create(:internal_chat_channel_member, channel: channel, user: sender)
        create(:internal_chat_channel_member, channel: channel, user: member)
        message = create(:internal_chat_message, account: account, channel: channel, sender: sender, content: '@all please review')

        expect { described_class.new(message: message).perform }.not_to change(Notification, :count)
      end

      it 'creates a mention notification even when the mentioned member has muted the channel' do
        muted_member = create(:user, account: account, role: :agent)
        create(:internal_chat_channel_member, channel: channel, user: sender)
        create(:internal_chat_channel_member, :muted, channel: channel, user: muted_member)
        message = create(
          :internal_chat_message, account: account, channel: channel, sender: sender,
                                  content: "Hey (mention://user/#{muted_member.id}/#{muted_member.name}) check this"
        )

        described_class.new(message: message).perform

        expect(Notification.where(user: muted_member, notification_type: 'internal_chat_mention')).to exist
      end
    end

    context 'with a direct message' do
      let(:channel) { create(:internal_chat_channel, :dm, account: account) }
      let(:recipient) { create(:user, account: account, role: :agent) }

      before do
        create(:internal_chat_channel_member, channel: channel, user: sender)
        create(:internal_chat_channel_member, channel: channel, user: recipient)
      end

      it 'creates a new_message notification for the recipient' do
        message = create(:internal_chat_message, account: account, channel: channel, sender: sender, content: 'hey there')

        described_class.new(message: message).perform

        notification = Notification.find_by(user: recipient, notification_type: 'internal_chat_new_message')
        expect(notification).to have_attributes(primary_actor: channel, secondary_actor: message)
      end

      it 'does not notify the sender' do
        message = create(:internal_chat_message, account: account, channel: channel, sender: sender, content: 'hey there')

        described_class.new(message: message).perform

        expect(Notification.where(user: sender)).not_to exist
      end

      it 'does not create a notification when the recipient muted the DM' do
        recipient_membership = channel.channel_members.find_by(user: recipient)
        recipient_membership.update!(muted: true)
        message = create(:internal_chat_message, account: account, channel: channel, sender: sender, content: 'hey there')

        expect { described_class.new(message: message).perform }.not_to change(Notification, :count)
      end
    end
  end

  context 'when the recipient lacks internal_chat.access' do
    it 'does not notify them, even when mentioned' do
      channel = create(:internal_chat_channel, :public_channel, account: account)
      mentioned_user = create(:user, account: account, role: :agent)
      create(:internal_chat_channel_member, channel: channel, user: sender)
      create(:internal_chat_channel_member, channel: channel, user: mentioned_user)
      message = create(
        :internal_chat_message, account: account, channel: channel, sender: sender,
                                content: "Hey (mention://user/#{mentioned_user.id}/#{mentioned_user.name})"
      )
      stub_const('FeatureAccess::CAPABILITIES', { 'internal_chat.access' => { agent_default: false } })

      expect { described_class.new(message: message).perform }.not_to change(Notification, :count)
    end
  end
end
