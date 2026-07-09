class AddCascadeToCrmRelatedForeignKeys < ActiveRecord::Migration[7.0]
  TARGET_FOREIGN_KEYS = [
    [:crm_cards, :contacts, :contact_id],
    [:crm_follow_ups, :contacts, :contact_id],
    [:crm_meeting_guests, :contacts, :contact_id],
    [:whatsapp_api_campaign_recipients, :contacts, :contact_id],
    [:crm_activities, :conversations, :conversation_id],
    [:crm_cards, :conversations, :conversation_id],
    [:crm_follow_ups, :conversations, :conversation_id],
    [:whatsapp_api_campaign_recipients, :conversations, :conversation_id],
    [:crm_activities, :crm_cards, :card_id],
    [:crm_ai_stage_suggestions, :crm_cards, :card_id],
    [:crm_card_conversations, :crm_cards, :card_id],
    [:crm_follow_ups, :crm_cards, :card_id],
    [:crm_meetings, :crm_cards, :card_id],
    [:crm_stage_automation_executions, :crm_cards, :card_id]
  ].freeze

  def up
    TARGET_FOREIGN_KEYS.each do |from_table, to_table, column|
      replace_foreign_key(from_table, to_table, column, on_delete: :cascade)
    end
  end

  def down
    TARGET_FOREIGN_KEYS.each do |from_table, to_table, column|
      replace_foreign_key(from_table, to_table, column)
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
