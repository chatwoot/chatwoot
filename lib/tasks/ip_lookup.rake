require 'rubygems/package'

namespace :ip_lookup do
  task setup: :environment do
    next if File.exist?(GeocoderConfiguration::LOOK_UP_DB)

    ip_lookup_api_key = ENV.fetch('IP_LOOKUP_API_KEY', nil)
    if ip_lookup_api_key.blank?
      Rails.logger.info '[rake ip_lookup:setup] IP_LOOKUP_API_KEY empty. Skipping geoip database setup'
      next
    end

    Rails.logger.info '[rake ip_lookup:setup] Fetch GeoLite2-City database'

    begin
      base_url = ENV.fetch('IP_LOOKUP_BASE_URL', 'https://download.maxmind.com/app/geoip_download')
      source_file = Down.download(
        "#{base_url}?edition_id=GeoLite2-City&suffix=tar.gz&license_key=#{ip_lookup_api_key}"
      )

      tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(source_file))
      tar_extract.rewind

      tar_extract.each do |entry|
        next unless entry.full_name.include?('GeoLite2-City.mmdb') && entry.file?

        File.open GeocoderConfiguration::LOOK_UP_DB, 'wb' do |f|
          f.print entry.read
        end
      end
      Rails.logger.info '[rake ip_lookup:setup] Fetch complete'
    rescue StandardError => e
      Rails.logger.error "[rake ip_lookup:setup] #{e.message}"
    end
  end
end
