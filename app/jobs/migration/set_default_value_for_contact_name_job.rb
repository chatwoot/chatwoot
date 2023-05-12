class Migration::SetDefaultValueForContactNameJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform(account)
    account.contacts.each do |contact|
      # rubocop:disable Rails/SkipsModelValidations
      contact.update_columns(name: '') if contact.name.blank?
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
end
