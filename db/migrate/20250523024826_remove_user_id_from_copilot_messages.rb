class RemoveUserIdFromCopilotMessages < ActiveRecord::Migration[7.1]
  def change
    remove_reference :copilot_messages, :user, index: true
  end
end
