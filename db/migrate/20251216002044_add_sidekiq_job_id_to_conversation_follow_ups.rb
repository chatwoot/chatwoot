class AddSidekiqJobIdToConversationFollowUps < ActiveRecord::Migration[7.1]
  def change
    add_column :conversation_follow_ups, :sidekiq_job_id, :string
    add_index :conversation_follow_ups, :sidekiq_job_id
  end
end
