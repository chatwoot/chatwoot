class RemoveTrainerIdFromChatbots < ActiveRecord::Migration[7.0]
  def change
    remove_column :chatbots, :trainer_id
  end
end
