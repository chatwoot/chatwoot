class ContactIpLookupJob < ApplicationJob
  queue_as :default

  def perform(contact)
    update_contact_location_from_ip(contact)
  rescue Errno::ETIMEDOUT => e
    Rails.logger.warn "Exception: ip resolution failed : #{e.message}"
  end

  private

  def update_contact_location_from_ip(contact)
    geocoder_result = IpLookupService.new.perform(get_contact_ip(contact))
    return unless geocoder_result

    # The lookup is a network call and this object was read before it, so the three keys go in
    # against the row as it is now rather than against a copy that predates the call.
    contact.merge_json_column!(
      :additional_attributes,
      merge: {
        'city' => geocoder_result.city,
        'country' => geocoder_result.country,
        'country_code' => geocoder_result.country_code
      }
    )
  end

  def get_contact_ip(contact)
    contact.additional_attributes&.dig('updated_at_ip') || contact.additional_attributes&.dig('created_at_ip')
  end
end
