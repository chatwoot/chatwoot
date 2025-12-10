# frozen_string_literal: true

# Service to manage the special inbox for WhatsApp group conversations
# This inbox is automatically created when the whatsapp_groups feature is enabled
# and is used to group all WhatsApp group conversations
class Whatsapp::GroupsInboxService
  pattr_initialize [:account!]

  GROUPS_INBOX_NAME = 'WhatsApp Groups'

  def find_or_create_groups_inbox
    find_existing_groups_inbox || create_groups_inbox
  end

  def find_existing_groups_inbox
    Inbox.where(account_id: account.id).where(channel_type: 'Channel::Api').where("inboxes.auto_assignment_config->>'is_whatsapp_groups_inbox' = 'true'").first
  end

  private

  def create_groups_inbox
    ActiveRecord::Base.transaction do
      channel = create_api_channel
      inbox = Inbox.create!(
        account_id: account.id,
        name: GROUPS_INBOX_NAME,
        channel_id: channel.id,
        channel_type: 'Channel::Api',
        enable_auto_assignment: false,
        lock_to_single_conversation: true,
        auto_assignment_config: {
          is_whatsapp_groups_inbox: true
        }
      )

      Rails.logger.info "[WHATSAPP GROUPS INBOX] Created groups inbox: #{inbox.id} for account: #{account.id}"
      inbox
    end
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP GROUPS INBOX] Error creating groups inbox: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    nil
  end

  def create_api_channel
    Channel::Api.create!(account_id: account.id)
  end
end
