class UpdateContactableContactsCountJob < ApplicationJob
  queue_as :default

  def perform(account_id)
    account = Account.find_by(id: account_id)
    return unless account

    # rubocop:disable Rails/SkipsModelValidations
    account.update_column(
      :contactable_contacts_count,
      account.contacts.contactable.count
    )
    # rubocop:enable Rails/SkipsModelValidations
  end
end
