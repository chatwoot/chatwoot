class Migration::PopulateAccountContactStatusAndSocialsJob < ApplicationJob
  queue_as :async_database_migration

  def perform(account_id)
    account = Account.find_by(id: account_id)
    return unless account

    Rails.logger.info "Processing contact migration for account #{account_id} (#{account.name})"

    # Find the first lead contact to determine cutoff
    first_lead = account.contacts.lead.order(:created_at).first

    # Build the contacts scope in a more readable way
    contacts_scope = if first_lead.present?
                       account.contacts.visitor.where('created_at < ?', first_lead.created_at)
                     else
                       account.contacts.visitor
                     end

    total_count = contacts_scope.count
    processed_count = 0

    contacts_scope.find_each(batch_size: 500) do |contact|
      processed_count += 1 if sync_contact_attributes(contact)
    end

    Rails.logger.info "Processed #{processed_count}/#{total_count} contacts for account #{account_id}"
  end

  private

  def sync_contact_attributes(contact)
    # Track only the fields we care about
    original_contact_type = contact.contact_type
    original_additional = contact.additional_attributes.dup

    # Run the sync service with migration
    ::Contacts::SyncAttributes.new(contact).perform_with_migration

    # Build update hash with only changed fields we care about
    update_hash = {}
    update_hash[:contact_type] = contact.contact_type if contact.contact_type != original_contact_type
    update_hash[:additional_attributes] = contact.additional_attributes if contact.additional_attributes != original_additional

    return false if update_hash.empty?

    # Use update_columns to bypass callbacks and avoid triggering events
    # rubocop:disable Rails/SkipsModelValidations
    contact.update_columns(update_hash)
    # rubocop:enable Rails/SkipsModelValidations
    true
  end
end
