require 'rails_helper'

describe NotificationBuilder do
  include ActiveJob::TestHelper

  describe '#perform' do
    let!(:account) { create(:account) }
    let!(:user) { create(:user, account: account) }
    let!(:inbox) { create(:inbox, account: account) }
    let!(:primary_actor) { create(:conversation, account: account, inbox: inbox) }

    before do
      create(:inbox_member, user: user, inbox: inbox)
      notification_setting = user.notification_settings.find_by(account_id: account.id)
      notification_setting.selected_email_flags = [:email_conversation_creation]
      notification_setting.selected_push_flags = [:push_conversation_creation]
      notification_setting.save!
    end

    it 'creates a notification' do
      expect do
        described_class.new(
          notification_type: 'conversation_creation',
          user: user,
          account: account,
          primary_actor: primary_actor
        ).perform
      end.to change { user.notifications.count }.by(1)
    end

    it 'will not throw error if notification setting is not present' do
      perform_enqueued_jobs do
        user.account_users.destroy_all
      end
      expect(
        described_class.new(
          notification_type: 'conversation_creation',
          user: user,
          account: account,
          primary_actor: primary_actor
        ).perform
      ).to be_nil
    end

    it 'will not create a conversation_creation notification if user is not subscribed to it' do
      notification_setting = user.notification_settings.find_by(account_id: account.id)
      notification_setting.selected_email_flags = []
      notification_setting.selected_push_flags = []
      notification_setting.save!

      expect(
        described_class.new(
          notification_type: 'conversation_creation',
          user: user,
          account: account,
          primary_actor: primary_actor
        ).perform
      ).to be_nil
    end

    it 'will create a conversation_mention notification even though user is not subscribed to it' do
      notification_setting = user.notification_settings.find_by(account_id: account.id)
      notification_setting.selected_email_flags = []
      notification_setting.selected_push_flags = []
      notification_setting.save!

      expect do
        described_class.new(
          notification_type: 'conversation_mention',
          user: user,
          account: account,
          primary_actor: primary_actor
        ).perform
      end.to change { user.notifications.count }.by(1)
    end

    it 'will not create a notification if conversation contact is blocked and notification type is not conversation_mention' do
      primary_actor.contact.update(blocked: true)

      expect do
        described_class.new(
          notification_type: 'conversation_creation',
          user: user,
          account: account,
          primary_actor: primary_actor
        ).perform
      end.not_to(change { user.notifications.count })
    end

    it 'will create a notification if conversation contact is blocked and notification type is conversation_mention' do
      primary_actor.contact.update(blocked: true)

      expect do
        described_class.new(
          notification_type: 'conversation_mention',
          user: user,
          account: account,
          primary_actor: primary_actor
        ).perform
      end.to change { user.notifications.count }.by(1)
    end

    context 'when the user does not have access to the conversation' do
      let!(:outsider) { create(:user, account: account) }

      it 'does not create a notification for an agent without inbox or team access' do
        expect do
          described_class.new(
            notification_type: 'conversation_creation',
            user: outsider,
            account: account,
            primary_actor: primary_actor
          ).perform
        end.not_to(change { outsider.notifications.count })
      end

      it 'still creates a notification for administrators regardless of inbox membership' do
        admin = create(:user, account: account, role: :administrator)
        admin_setting = admin.notification_settings.find_by(account_id: account.id)
        admin_setting.selected_email_flags = [:email_conversation_creation]
        admin_setting.selected_push_flags = [:push_conversation_creation]
        admin_setting.save!

        expect do
          described_class.new(
            notification_type: 'conversation_creation',
            user: admin,
            account: account,
            primary_actor: primary_actor
          ).perform
        end.to change { admin.notifications.count }.by(1)
      end

      it 'does not create a notification when the user is not part of the account' do
        unrelated_user = create(:user)

        expect do
          described_class.new(
            notification_type: 'conversation_creation',
            user: unrelated_user,
            account: account,
            primary_actor: primary_actor
          ).perform
        end.not_to(change { unrelated_user.notifications.count })
      end

      it 'derives the conversation from a message primary_actor' do
        outsider_inbox = create(:inbox, account: account)
        message = create(:message, account: account, inbox: outsider_inbox,
                                   conversation: create(:conversation, account: account, inbox: outsider_inbox))

        expect do
          described_class.new(
            notification_type: 'conversation_mention',
            user: outsider,
            account: account,
            primary_actor: message.conversation,
            secondary_actor: message
          ).perform
        end.not_to(change { outsider.notifications.count })
      end
    end
  end
end
