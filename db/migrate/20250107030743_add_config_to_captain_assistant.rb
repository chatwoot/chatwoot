class AddConfigToCaptainAssistant < ActiveRecord::Migration[7.0]
  def change
    add_column :captain_assistants, :config, :jsonb, default: {}, null: false
  end
end
