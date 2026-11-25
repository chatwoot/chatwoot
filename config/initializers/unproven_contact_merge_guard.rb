# frozen_string_literal: true

Rails.application.config.to_prepare do
  ContactIdentifyAction.prepend(UnprovenContactMergeGuard::IdentifyAction)
  ContactInboxWithContactBuilder.prepend(UnprovenContactMergeGuard::ContactBuilder)
  MessageTemplates::HookExecutionService.prepend(UnprovenContactMergeGuard::EmailCollect)
  Api::V1::Widget::ContactsController.prepend(UnprovenContactMergeGuard::WidgetContacts)
  Api::V1::Widget::ConversationsController.prepend(UnprovenContactMergeGuard::WidgetConversations)
  Api::V1::Widget::MessagesController.prepend(UnprovenContactMergeGuard::WidgetMessages)
  Public::Api::V1::Inboxes::ContactsController.prepend(UnprovenContactMergeGuard::PublicContacts)
end
