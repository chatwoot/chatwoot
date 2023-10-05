class IpLookupService
  def perform(ip_address)
    return if ip_address.blank?

    # Lazy load the geo database
    if !ip_database_available? && ENV['IP_LOOKUP_API_KEY'].present?
      Rails.application.load_tasks
      Rake::Task['ip_lookup:setup'].invoke
    end

    return unless ip_database_available?

    Geocoder.search(ip_address).first
  rescue Errno::ETIMEDOUT => e
    Rails.logger.warn "Exception: IP resolution failed :#{e.message}"
  end

  private

  def ip_database_available?
    File.exist?(GeocoderConfiguration::LOOK_UP_DB)
  end
end
