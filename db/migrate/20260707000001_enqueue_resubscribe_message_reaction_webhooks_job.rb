class EnqueueResubscribeMessageReactionWebhooksJob < ActiveRecord::Migration[7.1]
  def up
    Migration::ResubscribeMessageReactionWebhooksJob.perform_later
  end

  def down; end
end
