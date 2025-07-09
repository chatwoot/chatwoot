class SetDefaultEnterToSendEnabled < ActiveRecord::Migration[7.0]
  def up
    # Update all existing users to have enter_to_send_enabled = true by default
    # Only update users who don't have this setting explicitly configured
    execute <<-SQL
      UPDATE users 
      SET ui_settings = COALESCE(ui_settings, '{}'::jsonb) || '{"enter_to_send_enabled": true}'::jsonb
      WHERE ui_settings IS NULL 
         OR NOT ui_settings ? 'enter_to_send_enabled'
         OR ui_settings->>'enter_to_send_enabled' IS NULL;
    SQL

    # Also set editor_message_key to 'enter' for users who don't have it configured
    execute <<-SQL
      UPDATE users 
      SET ui_settings = ui_settings || '{"editor_message_key": "enter"}'::jsonb
      WHERE ui_settings IS NOT NULL 
        AND (NOT ui_settings ? 'editor_message_key' 
             OR ui_settings->>'editor_message_key' IS NULL
             OR ui_settings->>'editor_message_key' = '');
    SQL
  end

  def down
    # Revert to previous default behavior (cmd_enter)
    execute <<-SQL
      UPDATE users 
      SET ui_settings = ui_settings || '{"enter_to_send_enabled": false}'::jsonb
      WHERE ui_settings IS NOT NULL 
        AND ui_settings ? 'enter_to_send_enabled'
        AND ui_settings->>'enter_to_send_enabled' = 'true';
    SQL

    execute <<-SQL
      UPDATE users 
      SET ui_settings = ui_settings || '{"editor_message_key": "cmd_enter"}'::jsonb
      WHERE ui_settings IS NOT NULL 
        AND ui_settings ? 'editor_message_key'
        AND ui_settings->>'editor_message_key' = 'enter';
    SQL
  end
end
