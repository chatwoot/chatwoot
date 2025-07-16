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

  # integration tests to ensure that the order mention service and new message notification service are called in the correct order
  describe 'message_created - mentions, participation & assignment integration' do
    let(:event_name) { :'message.created' }

    it 'will not create duplicate new message notification for the same user for mentions participation & assignment' do
      create(:inbox_member, user: first_agent, inbox: inbox)
      conversation.update!(assignee: first_agent)

      message = build(
        :message,
        conversation: conversation,
        account: account,
        content: "hi [#{first_agent.name}](mention://user/#{first_agent.id}/#{first_agent.name})",
        private: true
      )
      event = Events::Base.new(event_name, Time.zone.now, message: message)
      listener.message_created(event)

      expect(first_agent.notifications.count).to eq(1)
      expect(first_agent.notifications.first.notification_type).to eq('conversation_mention')
    end

    it 'will not create duplicate new message notifications for assignment & participation' do
      create(:inbox_member, user: first_agent, inbox: inbox)
      conversation.update!(assignee: first_agent)
      # participants is created by async job. so creating it directly for testcase
      conversation.conversation_participants.first_or_create!(user: first_agent)

      message = build(
        :message,
        conversation: conversation,
        account: account,
        content: 'hi',
        private: true
      )

      event = Events::Base.new(event_name, Time.zone.now, message: message)
      listener.message_created(event)

      expect(conversation.conversation_participants.map(&:user)).to include(first_agent)
      expect(first_agent.notifications.count).to eq(1)
      expect(first_agent.notifications.first.notification_type).to eq('assigned_conversation_new_message')
    end
  end

  describe 'conversation_bot_handoff' do
    let(:event_name) { :'conversation.bot_handoff' }

    context 'when conversation is bot handoff' do
      it 'creates notifications for inbox members who have notifications turned on' do
        notification_setting = first_agent.notification_settings.first
        notification_setting.selected_email_flags = [:email_conversation_creation]
        notification_setting.selected_push_flags = []
        notification_setting.save!

        create(:inbox_member, user: first_agent, inbox: inbox)
        conversation.reload

        event = Events::Base.new(event_name, Time.zone.now, conversation: conversation)

        listener.conversation_bot_handoff(event)
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

        listener.conversation_bot_handoff(event)
        expect(notification_setting.user.notifications.count).to eq(0)
      end
    end
  end

  describe 'assignee_changed' do
    let(:event_name) { :'conversation.assignee_changed' }

    context 'when notifiable_assignee_change is true but assignee is nil' do
      it 'does not create a notification' do
        conversation_with_nil_assignee = create(:conversation, account: account, inbox: inbox, assignee: nil)

        notification_builder_mock = instance_double(NotificationBuilder)
        allow(NotificationBuilder).to receive(:new).and_return(notification_builder_mock)

        event = Events::Base.new(
          event_name,
          Time.zone.now,
          conversation: conversation_with_nil_assignee,
          data: { notifiable_assignee_change: true }
        )

        expect(notification_builder_mock).not_to receive(:perform)

        listener.assignee_changed(event)
      end
    end
  end
end
