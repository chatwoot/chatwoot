class RecalculateConversationPrioritiesJob < ApplicationJob
  queue_as :low

  def perform(account_id = nil)
    if account_id
      account = Account.find_by(id: account_id)
      return unless account

      recalculate_for_account(account)
    else
      # Recalculate for all accounts
      Account.find_each do |account|
        recalculate_for_account(account)
      end
    end
  end

  private

  def recalculate_for_account(account)
    Rails.logger.info("Recalculating priorities for account #{account.id}")
    ConversationPriorityService.recalculate_all_open_conversations(account)
  rescue StandardError => e
    Rails.logger.error("Failed to recalculate priorities for account #{account.id}: #{e.message}")
  end
end
