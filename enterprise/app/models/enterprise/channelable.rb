module Enterprise::Channelable
  extend ActiveSupport::Concern

  AUDIT_EXCLUDED_ATTRIBUTES = %w[
    updated_at
    secret
    provider_config
    access_token
    refresh_token
    imap_password
    smtp_password
    line_channel_secret
    line_channel_token
    page_access_token
    user_access_token
    auth_token
    api_key_sid
    api_key_secret
    bot_token
    business_management_token
    twitter_access_token
    twitter_access_token_secret
  ].freeze

  # Active support concern has `included` which changes the order of the method lookup chain
  # https://stackoverflow.com/q/40061982/3824876
  # manually prepend the instance methods to combat this
  included do
    prepend InstanceMethods
  end

  module InstanceMethods
    def create_audit_log_entry
      account = self.account
      associated_type = 'Account'

      return if inbox.nil?

      auditable_id = inbox.id
      auditable_type = 'Inbox'
      audited_changes = saved_changes.except(*AUDIT_EXCLUDED_ATTRIBUTES, *self.class.encrypted_attributes.to_a.map(&:to_s))

      return if audited_changes.blank?

      # skip audit log creation if the only change is whatsapp channel template update
      return if messaging_template_updates?(audited_changes)

      Enterprise::AuditLog.create(
        auditable_id: auditable_id,
        auditable_type: auditable_type,
        action: 'update',
        associated_id: account.id,
        associated_type: associated_type,
        audited_changes: audited_changes
      )
    end

    def messaging_template_updates?(changes)
      # if there is more than one key, return false
      return false unless changes.keys.length == 1

      # if the only key is message_templates_last_updated, return true
      changes.key?('message_templates_last_updated')
    end
  end
end
