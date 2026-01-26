class AddProcessingStartedAtToConversationFollowUps < ActiveRecord::Migration[7.1]
  def change
    # Column already exists, so we only add the composite index
    
    # Composite index for optimization of the Dispatcher job:
    # 1. status: 'active'
    # 2. next_action_at: <= Time.current
    # 3. processing_started_at: nil (unlocked)
    add_index :conversation_follow_ups, [:status, :next_action_at, :processing_started_at], name: 'index_follow_ups_dispatcher_optimization' 
  end
end
