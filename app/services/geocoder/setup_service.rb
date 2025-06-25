require 'rubygems/package'

class Geocoder::SetupService
  def perform
    return if File.exist?(GeocoderConfiguration::LOOK_UP_DB)

    ip_lookup_api_key = ENV.fetch('IP_LOOKUP_API_KEY', nil)
    if ip_lookup_api_key.blank?
      log_info('IP_LOOKUP_API_KEY empty. Skipping geoip database setup')
      return
    end

    log_info('Fetch GeoLite2-City database')
    fetch_and_extract_database(ip_lookup_api_key)
  end

  private

  def fetch_and_extract_database(api_key)
    base_url = ENV.fetch('IP_LOOKUP_BASE_URL', 'https://download.maxmind.com/app/geoip_download')
    source_file = Down.download("#{base_url}?edition_id=GeoLite2-City&suffix=tar.gz&license_key=#{api_key}")

    extract_tar_file(source_file)
    log_info('Fetch complete')
  rescue StandardError => e
    log_error(e.message)
  end

  def extract_tar_file(source_file)
    tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(source_file))
    tar_extract.rewind

    tar_extract.each do |entry|
      next unless entry.full_name.include?('GeoLite2-City.mmdb') && entry.file?

      File.open GeocoderConfiguration::LOOK_UP_DB, 'wb' do |f|
        f.print entry.read
      end
    end
  end

  def log_info(message)
    Rails.logger.info "[rake ip_lookup:setup] #{message}"
  end

  def log_error(message)
    Rails.logger.error "[rake ip_lookup:setup] #{message}"
  end
end
