class AddIncludePrivateNotesToWebhooks < ActiveRecord::Migration[7.1]
  def change
    add_column :webhooks, :include_private_notes, :boolean, default: false, null: false
  end
end
