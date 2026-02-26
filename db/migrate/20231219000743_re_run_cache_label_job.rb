class ReRunCacheLabelJob < ActiveRecord::Migration[7.0]
  def change
    update_exisiting_conversations
  end

  private

  def update_exisiting_conversations
    # Run label migrations on the accounts that are not suspended
    ::Account.active.find_in_batches do |account_batch|
      account_batch.each do |account|
        Migration::ConversationCacheLabelJob.perform_later(account)
      end
    end
  end
end
