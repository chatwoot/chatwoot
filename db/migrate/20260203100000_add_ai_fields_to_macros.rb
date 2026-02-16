class AddAiFieldsToMacros < ActiveRecord::Migration[7.0]
  def change
    add_column :macros, :description, :text
    add_column :macros, :ai_enabled, :boolean, default: false, null: false
    add_index :macros, %i[account_id ai_enabled], where: 'ai_enabled = true', name: 'index_macros_on_account_id_ai_enabled'
  end
end
