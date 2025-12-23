require 'geocoder/results/base'

module Geocoder
  module Result
    class Ipqualityscore < Base

      def self.key_method_mappings
        {
          'request_id' => :request_id,
          'success' => :success?,
          'message' => :message,
          'city' => :city,
          'region' => :state,
          'country_code' => :country_code,
          'mobile' => :mobile?,
          'fraud_score' => :fraud_score,
          'ISP' => :isp,
          'ASN' => :asn,
          'organization' => :organization,
          'is_crawler' => :crawler?,
          'host' => :host,
          'proxy' => :proxy?,
          'vpn' => :vpn?,
          'tor' => :tor?,
          'active_vpn' => :active_vpn?,
          'active_tor' => :active_tor?,
          'recent_abuse' => :recent_abuse?,
          'bot_status' => :bot?,
          'connection_type' => :connection_type,
          'abuse_velocity' => :abuse_velocity,
          'timezone' => :timezone,
        }
      end

      key_method_mappings.each_pair do |key, meth|
        define_method meth do
          @data[key]
        end
      end

      alias_method :state_code, :state
      alias_method :country, :country_code

      def postal_code
        '' # No suitable fallback
      end

      def address
        [city, state, country_code].compact.reject(&:empty?).join(', ')
      end

    end
  end
end
