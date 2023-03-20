class IpLookupService
  def perform(ip_address)
    return if ip_address.blank? || !ip_database_available?

    Geocoder.search(ip_address).first
  rescue Errno::ETIMEDOUT => e
    Rails.logger.warn "Exception: IP resolution failed :#{e.message}"
  end

  private

  def ip_database_available?
    File.exist?(GeocoderConfiguration::LOOK_UP_DB)
  end
end
