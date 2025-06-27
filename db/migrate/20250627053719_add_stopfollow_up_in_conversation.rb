class AddStopfollowUpInConversation < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :stop_follow_up, :boolean, default: :false
  end
end
