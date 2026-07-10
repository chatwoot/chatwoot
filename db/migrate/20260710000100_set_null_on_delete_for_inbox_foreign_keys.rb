class SetNullOnDeleteForInboxForeignKeys < ActiveRecord::Migration[7.0]
  TARGET_FOREIGN_KEYS = [
    [:autonomia_agent_inboxes, :inboxes, :inbox_id],
    [:crm_cards, :inboxes, :inbox_id],
    [:crm_follow_ups, :inboxes, :inbox_id],
    [:crm_inbox_settings, :inboxes, :inbox_id],
    [:crm_pipeline_inboxes, :inboxes, :inbox_id],
    [:crm_agent_booking_links, :inboxes, :inbox_id],
    [:crm_agent_booking_profiles, :inboxes, :inbox_id],
    [:crm_calendar_sync_states, :inboxes, :inbox_id],
    [:email_campaigns, :inboxes, :sender_inbox_id],
    [:whatsapp_api_campaign_recipients, :inboxes, :inbox_id],
    [:whatsapp_api_campaigns, :inboxes, :inbox_id],
    [:whatsapp_api_message_templates, :inboxes, :inbox_id]
  ].freeze

  REQUIRED_COLUMNS = [
    [:autonomia_agent_inboxes, :inbox_id],
    [:crm_inbox_settings, :inbox_id],
    [:crm_pipeline_inboxes, :inbox_id],
    [:crm_agent_booking_links, :inbox_id],
    [:crm_agent_booking_profiles, :inbox_id],
    [:crm_calendar_sync_states, :inbox_id],
    [:whatsapp_api_campaign_recipients, :inbox_id],
    [:whatsapp_api_campaigns, :inbox_id],
    [:whatsapp_api_message_templates, :inbox_id]
  ].freeze

  def up
    REQUIRED_COLUMNS.each do |table, column|
      change_column_null table, column, true
    end

    TARGET_FOREIGN_KEYS.each do |from_table, to_table, column|
      replace_foreign_key(from_table, to_table, column, on_delete: :nullify)
    end
  end

  def down
    TARGET_FOREIGN_KEYS.each do |from_table, to_table, column|
      replace_foreign_key(from_table, to_table, column)
    end

    REQUIRED_COLUMNS.each do |table, column|
      change_column_null table, column, false
    end
  end

  private

  def replace_foreign_key(from_table, to_table, column, on_delete: nil)
    return unless foreign_key_exists?(from_table, to_table, column: column)

    remove_foreign_key from_table, column: column
    options = { column: column }
    options[:on_delete] = on_delete if on_delete.present?
    add_foreign_key from_table, to_table, **options
  end
end
