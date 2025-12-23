require 'geocoder/results/geoip2'

module Geocoder::Result
  class MaxmindGeoip2 < Geoip2
    # MindmindGeoip2 has the same results as Geoip2 because both are from MaxMind's GeoIP2 Precision Services
    # See http://dev.maxmind.com/geoip/geoip2/web-services/ The difference being that Maxmind calls the service
    # directly while GeoIP2 uses Hive::GeoIP2. See https://github.com/desuwa/hive_geoip2
  end
end
