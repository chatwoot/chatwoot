class RenameUserLastSeen < ActiveRecord::Migration[6.0]
  def change
    rename_column :conversations, :user_last_seen_at, :contact_last_seen_at
  end
end
