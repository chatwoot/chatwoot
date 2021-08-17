require 'rubygems/package'

class ContactIpLookupJob < ApplicationJob
  queue_as :default

  def perform(contact)
    return unless ensure_look_up_service

    update_contact_location_from_ip(contact)
  rescue Errno::ETIMEDOUT => e
    Rails.logger.info "Exception: ip resolution failed : #{e.message}"
  end

  private

  def ensure_look_up_service
    return if ENV['IP_LOOKUP_SERVICE'].blank? || ENV['IP_LOOKUP_API_KEY'].blank?
    return true if ENV['IP_LOOKUP_SERVICE'].to_sym != :geoip2

    ensure_look_up_db
  end

  def update_contact_location_from_ip(contact)
    ip = get_contact_ip(contact)
    return if ip.blank?

    geocoder_result = Geocoder.search(ip).first
    return unless geocoder_result

    contact.additional_attributes['city'] = geocoder_result.city
    contact.additional_attributes['country'] = geocoder_result.country
    contact.additional_attributes['country_code'] = geocoder_result.country_code
    contact.save!
  end

  def get_contact_ip(contact)
    contact.additional_attributes['updated_at_ip'] || contact.additional_attributes['created_at_ip']
  end

  def ensure_look_up_db
    return true if File.exist?(GeocoderConfiguration::LOOK_UP_DB)

    setup_vendor_db
  end

  def setup_vendor_db
    base_url = 'https://download.maxmind.com/app/geoip_download'
    source_file = Down.download(
      "#{base_url}?edition_id=GeoLite2-City&suffix=tar.gz&license_key=#{ENV['IP_LOOKUP_API_KEY']}"
    )
    tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(source_file))
    tar_extract.rewind

    tar_extract.each do |entry|
      next unless entry.full_name.include?('GeoLite2-City.mmdb') && entry.file?

      File.open GeocoderConfiguration::LOOK_UP_DB, 'wb' do |f|
        f.print entry.read
      end
      return true
    end
  end
end
