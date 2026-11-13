class BackfillConversationLastMessageAt < ActiveRecord::Migration[7.1]
  def up
    Migration::BackfillConversationLastMessageAtJob.perform_later
  end
end
