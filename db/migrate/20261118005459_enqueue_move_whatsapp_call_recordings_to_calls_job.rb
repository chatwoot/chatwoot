class EnqueueMoveWhatsappCallRecordingsToCallsJob < ActiveRecord::Migration[8.0]
  def up
    Migration::MoveWhatsappCallRecordingsToCallsJob.perform_later if ChatwootApp.enterprise?
  end

  def down; end
end
