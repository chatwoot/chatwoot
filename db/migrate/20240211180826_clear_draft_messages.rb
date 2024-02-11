class ClearDraftMessages < ActiveRecord::Migration[7.0]
  def change
    Migration::FixInvalidEmailsJob.perform_later
    Migration::ClearConversationDraftJob.perform_later
  end
end
