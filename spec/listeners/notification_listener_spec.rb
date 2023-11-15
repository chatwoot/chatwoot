require 'rails_helper'
describe NotificationListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:first_agent) { create(:user, account: account) }
  let!(:agent_with_out_notification) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }

  describe 'conversation_created' do
    let(:event_name) { :'conversation.created' }

    context 'when conversation is created' do
      it 'creates notifications for inbox members who have notifications turned on' do
        notification_setting = first_agent.notification_settings.first
        notification_setting.selected_email_flags = [:email_conversation_creation]
        notification_setting.selected_push_flags = []
        notification_setting.save!

        create(:inbox_member, user: first_agent, inbox: inbox)
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

    before do
      notification_setting = first_agent.notification_settings.find_by(account_id: account.id)
      notification_setting.selected_email_flags = [:email_conversation_mention]
      notification_setting.selected_push_flags = []
      notification_setting.save!
    end

    it 'will call mention service' do
      mention_service = instance_double(Messages::MentionService)
      allow(Messages::MentionService).to receive(:new).and_return(mention_service)
      allow(mention_service).to receive(:perform)

      create(:inbox_member, user: first_agent, inbox: inbox)
      conversation.reload

      message = build(
        :message,
        conversation: conversation,
        account: account,
        content: "hi [#{first_agent.name}](mention://user/#{first_agent.id}/#{first_agent.name})",
        private: true
      )

      expect(mention_service).to receive(:perform)
      event = Events::Base.new(event_name, Time.zone.now, message: message)
      listener.message_created(event)
    end

    it 'will call new message notification service' do
      notification_service = instance_double(Messages::NewMessageNotificationService)
      allow(Messages::NewMessageNotificationService).to receive(:new).and_return(notification_service)
      allow(notification_service).to receive(:perform)

      create(:inbox_member, user: first_agent, inbox: inbox)
      conversation.reload

      message = build(
        :message,
        conversation: conversation,
        account: account,
        content: 'hi',
        private: true
      )

      expect(notification_service).to receive(:perform)
      event = Events::Base.new(event_name, Time.zone.now, message: message)
      listener.message_created(event)
    end

    context 'when message content is empty' do
      it 'will be processed correctly' do
        builder = double
        allow(NotificationBuilder).to receive(:new).and_return(builder)
        allow(builder).to receive(:perform)

        create(:inbox_member, user: first_agent, inbox: inbox)
        conversation.reload

        message = build(
          :message,
          conversation: conversation,
          account: account,
          content: nil,
          private: true
        )

        event = Events::Base.new(event_name, Time.zone.now, message: message)
        # want to validate message_created doesnt throw an error
        expect { listener.message_created(event) }.not_to raise_error
      end
    end
  end
end
