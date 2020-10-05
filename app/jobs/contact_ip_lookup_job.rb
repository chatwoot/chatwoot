class ContactIpLookupJob < ApplicationJob
  queue_as :default

  def perform(contact)
    ip = contact.additional_attributes[:updated_at_ip] || contact.additional_attributes[:created_at_ip]
    return unless ip

    contact.additional_attributes[:city] = Geocoder.search(ip).first.city
    contact.additional_attributes[:country] = Geocoder.search(ip).first.country
    contact.save!
  rescue Errno::ETIMEDOUT => e
    Rails.logger.info "Exception: invalid avatar url #{avatar_url} : #{e.message}"
  end
end
