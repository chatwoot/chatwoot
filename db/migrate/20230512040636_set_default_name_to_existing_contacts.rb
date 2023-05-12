class SetDefaultNameToExistingContacts < ActiveRecord::Migration[7.0]
  def change
    ::Account.find_in_batches do |account_batch|
      Rails.logger.info "Migrated till #{account_batch.first.id}\n"
      account_batch.each do |account|
        Migration::SetDefaultValueForContactNameJob.perform_later(account)
      end
    end
  end
end
