require 'rails_helper'
describe NotificationListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:agent_with_notification) { create(:user, account: account) }
  let!(:agent_with_out_notification) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }

  describe 'conversation_created' do
    let(:event_name) { :'conversation.created' }

    context 'when conversation is created' do
      it 'creates notifications for inbox members who have notifications turned on' do
        notification_setting = agent_with_notification.notification_settings.first
        notification_setting.selected_email_flags = [:email_conversation_creation]
        notification_setting.selected_push_flags = []
        notification_setting.save!

        create(:inbox_member, user: agent_with_notification, inbox: inbox)
        conversation.reload

        event = Events::Base.new(event_name, Time.zone.now, conversation: conversation)

        listener.conversation_created(event)
        expect(notification_setting.user.notifications.count).to eq(1)
      end

      it 'does not create notification for inbox members who have notifications turned off' do
        notification_setting = agent_with_out_notification.notification_settings.first
        notification_setting.unselect_all_email_flags
        notification_setting.unselect_all_push_flags
        notification_setting.save!

        create(:inbox_member, user: agent_with_out_notification, inbox: inbox)
        conversation.reload

        event = Events::Base.new(event_name, Time.zone.now, conversation: conversation)

        listener.conversation_created(event)
        expect(notification_setting.user.notifications.count).to eq(0)
      end
    end
  end

  describe 'message_created' do
    let(:event_name) { :'message.created' }

    context 'when message contains mention' do
      it 'creates notifications for inbox member who was mentioned' do
        notification_setting = agent_with_notification.notification_settings.find_by(account_id: account.id)
        notification_setting.selected_email_flags = [:email_conversation_mention]
        notification_setting.selected_push_flags = []
        notification_setting.save!

        builder = double
        allow(NotificationBuilder).to receive(:new).and_return(builder)
        allow(builder).to receive(:perform)

        create(:inbox_member, user: agent_with_notification, inbox: inbox)
        conversation.reload

        message = build(
          :message,
          conversation: conversation,
          account: account,
          content: "hi [#{agent_with_notification.name}](mention://user/#{agent_with_notification.id}/#{agent_with_notification.name})",
          private: true
        )

        event = Events::Base.new(event_name, Time.zone.now, message: message)
        listener.message_created(event)

        expect(NotificationBuilder).to have_received(:new).with(notification_type: 'conversation_mention',
                                                                user: agent_with_notification,
                                                                account: account,
                                                                primary_actor: message)
      end
    end
  end
end
