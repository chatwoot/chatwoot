class Migration::BackfillConversationLastMessageAtJob < ApplicationJob
  queue_as :async_database_migration

  BATCH_SIZE = 100

  def perform(account, after_id = 0, through_id = nil)
    through_id ||= account.conversations.maximum(:id).to_i

    batch = account.conversations.where(id: (after_id + 1)..through_id).order(:id).limit(BATCH_SIZE)
    rows = batch.pluck(:id, :last_message_at, latest_public_message_time(account))
    reconcile_rows(account, rows)
    if rows.size == BATCH_SIZE && rows.last.first < through_id
      self.class.set(wait: 1.second).perform_later(account, rows.last.first, through_id)
    else
      Rails.logger.info("Completed last_message_at backfill for account #{account.id} through conversation #{through_id}")
    end
  end

  private

  def reconcile_rows(account, rows)
    rows.each do |id, stored, latest|
      next if latest.nil? || (stored && stored >= latest)

      account.conversations.advance_last_message_at(id, latest)
    end
  end

  def latest_public_message_time(account)
    # The shipped message index starts with conversation, account and type.
    # One descending probe per type also bounds reads for long public histories.
    messages = Message.chat.where(account_id: account.id)
                      .where(Message.arel_table[:conversation_id].eq(Conversation.arel_table[:id]))
    latest_by_type = Message.message_types.except('activity').keys.map do |type|
      messages.where(message_type: type).reorder(created_at: :desc).limit(1).select(:created_at).arel
    end
    Arel::Nodes::NamedFunction.new('GREATEST', latest_by_type)
  end
end
