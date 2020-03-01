require 'rails_helper'
describe EmailNotificationListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:agent_with_notification) { create(:user, account: account) }
  let!(:agent_with_out_notification) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }

  describe 'conversation_created' do
    let(:event_name) { :'conversation.created' }

    before do
      creation_mailer = double
      allow(AgentNotifications::ConversationNotificationsMailer).to receive(:conversation_created).and_return(creation_mailer)
      allow(creation_mailer).to receive(:deliver_later).and_return(true)
    end

    context 'when conversation is created' do
      it 'sends email to inbox members who have notifications turned on' do
        notification_setting = agent_with_notification.notification_settings.first
        notification_setting.selected_email_flags = [:conversation_creation]
        notification_setting.save!

        create(:inbox_member, user: agent_with_notification, inbox: inbox)
        conversation.reload

        event = Events::Base.new(event_name, Time.zone.now, conversation: conversation)

        listener.conversation_created(event)
        expect(AgentNotifications::ConversationNotificationsMailer).to have_received(:conversation_created)
          .with(conversation, agent_with_notification)
      end

      it 'does not send and email to inbox members who have notifications turned off' do
        notification_setting = agent_with_notification.notification_settings.first
        notification_setting.unselect_all_email_flags
        notification_setting.save!

        create(:inbox_member, user: agent_with_out_notification, inbox: inbox)
        conversation.reload

        event = Events::Base.new(event_name, Time.zone.now, conversation: conversation)

        listener.conversation_created(event)
        expect(AgentNotifications::ConversationNotificationsMailer).not_to have_received(:conversation_created)
          .with(conversation, agent_with_out_notification)
      end
    end
  end
end
