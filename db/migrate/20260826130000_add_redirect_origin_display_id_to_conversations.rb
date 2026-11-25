class AddRedirectOriginDisplayIdToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :redirect_origin_display_id, :integer
  end
end
