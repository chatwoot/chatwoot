class Internal::RemoveOrphanedContactsService
  # by default, purge contacts older than 6 months
  attr_reader :account_id, :offset, :account, :deleted_count

  def initialize(account_id:, offset: 180.days)
    @account_id = account_id
    @account = Account.find(account_id)
    raise ArgumentError, 'Account not found' if @account.nil?

    @offset = offset
    @deleted_count = 0
  end

  def perform
    Rails.logger.info "Starting contact purge for account #{account_id} for #{offset / 1.day} days"

    base_query.find_in_batches(batch_size: 100) do |contacts_batch|
      process_batch(contacts_batch)
    end

    Rails.logger.info "Completed contact purge for account #{account_id}. Total contacts deleted: #{deleted_count}"
  end

  private

  def process_batch(contacts_batch)
    batch_deleted = 0

    contacts_batch.each do |contact|
      next if contact.conversations.exists?

      contact.destroy!
      batch_deleted += 1
      @deleted_count += 1
    end

    Rails.logger.info "Processed batch of #{contacts_batch.size} contacts, deleted #{batch_deleted} for account #{account_id}"
  end

  def base_query
    account.contacts.where('created_at < ?', Time.zone.now - offset)
  end
end
