class EnqueueMoveWhatsappCallRecordingsToCallsJob < ActiveRecord::Migration[8.0]
  def up
    return unless ChatwootApp.enterprise?

    # Wait for a rolling deploy to finish, so old app servers have stopped attaching recordings to messages
    Migration::MoveWhatsappCallRecordingsToCallsJob.set(wait: 1.hour).perform_later
  end

  def down; end
end
