require 'rubygems/package'

class IpLookupService
  pattr_initialize [sync_lookup: true]

  def perform(ip_address)
    return if ip_address.blank?
    return unless ensure_look_up_service

    Geocoder.search(ip_address).first
  rescue Errno::ETIMEDOUT => e
    Rails.logger.warn "Exception: ip resolution failed : #{e.message}"
  end

  private

  def ensure_look_up_service
    return if ENV['IP_LOOKUP_SERVICE'].blank? || ENV['IP_LOOKUP_API_KEY'].blank?
    return true if ENV['IP_LOOKUP_SERVICE'].to_sym != :geoip2

    ensure_look_up_db
  end

  def ensure_look_up_db
    return true if File.exist?(GeocoderConfiguration::LOOK_UP_DB)

    setup_vendor_db
  end

  def setup_vendor_db
    return if sync_lookup == true

    base_url = 'https://download.maxmind.com/app/geoip_download'
    source_file = Down.download(
      "#{base_url}?edition_id=GeoLite2-City&suffix=tar.gz&license_key=#{ENV.fetch('IP_LOOKUP_API_KEY', nil)}"
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
