require 'geocoder/lookups/baidu'
require 'geocoder/results/baidu_ip'

module Geocoder::Lookup
  class BaiduIp < Baidu

    def name
      "Baidu IP"
    end

    private # ---------------------------------------------------------------

    def base_query_url(query)
      "#{protocol}://api.map.baidu.com/location/ip?"
    end

    def content_key
      'content'
    end

    def query_url_params(query)
      {
        :ip => query.sanitized_text,
        :ak => configuration.api_key,
        :coor => "bd09ll"
      }.merge(super)
    end

  end
end
