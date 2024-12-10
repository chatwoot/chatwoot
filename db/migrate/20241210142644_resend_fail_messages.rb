class ResendFailMessages < ActiveRecord::Migration[7.0]
  def change
    Migration::ResendFailedMessagesJob.perform_later
  end
end
