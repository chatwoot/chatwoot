# Marks visitors that have identifying details as leads, matching Contacts::SyncAttributes.
# Contacts created before contact_type existed, or inserted without callbacks, were never
# classified, and the contacts list only shows leads and customers.
class Migration::BackfillContactTypeJob < ApplicationJob
  queue_as :low

  IDENTIFIED_CONTACT_CONDITION = <<~SQL.squish.freeze
    contacts.email <> '' OR contacts.phone_number <> '' OR contacts.identifier <> ''
    OR EXISTS (
      SELECT 1 FROM jsonb_each_text(contacts.additional_attributes) AS attribute
      WHERE attribute.key LIKE 'social\\_%' AND attribute.value NOT IN ('', '{}', 'null')
    )
  SQL

  def perform
    # rubocop:disable Rails/SkipsModelValidations
    Contact.visitor.in_batches(of: 10_000, use_ranges: true) do |contacts|
      contacts.where(IDENTIFIED_CONTACT_CONDITION).update_all(contact_type: Contact.contact_types[:lead])
    end
    # rubocop:enable Rails/SkipsModelValidations
  end
end
