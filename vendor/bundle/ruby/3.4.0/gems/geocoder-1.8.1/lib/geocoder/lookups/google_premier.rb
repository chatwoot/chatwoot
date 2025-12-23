require 'openssl'
require 'base64'
require 'geocoder/lookups/google'
require 'geocoder/results/google_premier'

module Geocoder::Lookup
  class GooglePremier < Google

    def name
      "Google Premier"
    end

    def required_api_key_parts
      ["private key"]
    end

    def query_url(query)
      path = "/maps/api/geocode/json?" + url_query_string(query)
      "#{protocol}://maps.googleapis.com#{path}&signature=#{sign(path)}"
    end

    private # ---------------------------------------------------------------

    def result_root_attr
      'results'
    end

    def cache_key(query)
      "#{protocol}://maps.googleapis.com/maps/api/geocode/json?" + hash_to_query(cache_key_params(query))
    end

    def cache_key_params(query)
      query_url_google_params(query).merge(super).reject do |k,v|
        [:key, :client, :channel].include?(k)
      end
    end

    def query_url_params(query)
      query_url_google_params(query).merge(super).merge(
        :key => nil, # don't use param inherited from Google lookup
        :client => configuration.api_key[1],
        :channel => configuration.api_key[2]
      )
    end

    def sign(string)
      raw_private_key = url_safe_base64_decode(configuration.api_key[0])
      digest = OpenSSL::Digest.new('sha1')
      raw_signature = OpenSSL::HMAC.digest(digest, raw_private_key, string)
      url_safe_base64_encode(raw_signature)
    end

    def url_safe_base64_decode(base64_string)
      Base64.decode64(base64_string.tr('-_', '+/'))
    end

    def url_safe_base64_encode(raw)
      Base64.encode64(raw).tr('+/', '-_').strip
    end
  end
end
