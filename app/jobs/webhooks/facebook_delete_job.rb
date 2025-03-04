class Webhooks::FacebookDeleteJob < ApplicationJob
  queue_as :low

  def perform(id_to_process)
    @id_to_process = id_to_process
    delete_contact_if_present

    unset_processing
  end

  private

  def unset_processing
    key = format(::Redis::Alfred::META_DELETE_PROCESSING, id: @id_to_process)
    ::Redis::Alfred.del(key)
  end

  def remove_contact_if_present
    contact_inbox = ContactInbox.find_by(source_id: @id_to_process)
    return unless contact_inbox

    contact = contact_inbox.contact
    contact.update!(
      name: 'Deleted User',
      email: nil,
      phone_number: nil,
      identifier: nil,
      additional_attributes: {},
      custom_attributes: {}
    )
  end
end
