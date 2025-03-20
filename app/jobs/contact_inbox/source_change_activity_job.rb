class ContactInbox::SourceChangeActivityJob < ApplicationJob
  queue_as :default

  def perform(contact_inbox_id, previous_source_id, current_source_id)
    contact_inbox = ContactInbox.find_by(id: contact_inbox_id)
    return if contact_inbox.blank?

    activity_message = I18n.t(
      activity_message_i18n_key(contact_inbox),
      previous: previous_source_id,
      current: current_source_id
    )

    contact_inbox.conversations.find_each(batch_size: 100) do |conversation|
      Conversations::ActivityMessageJob.perform_later(
        conversation,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        message: activity_message,
        message_type: :activity
      )
    end
  end

  private

  def activity_message_i18n_key(contact_inbox)
    type = if contact_inbox.inbox.email?
             :email_changed
           elsif contact_inbox.inbox.whatsapp?
             :phone_number_changed
           else
             :identifier_changed
           end

    "contact_inboxes.source_change.#{type}"
  end
end
