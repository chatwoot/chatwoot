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

    contact.additional_attributes ||= {}
    contact.additional_attributes['city'] = geocoder_result.city
    contact.additional_attributes['country'] = geocoder_result.country
    contact.additional_attributes['country_code'] = geocoder_result.country_code
    contact.save!
  end

  def get_contact_ip(contact)
    contact.additional_attributes&.dig('updated_at_ip') || contact.additional_attributes&.dig('created_at_ip')
  end
end
