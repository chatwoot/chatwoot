module Geocoder
  class EsriToken
    attr_accessor :value, :expires_at

    def initialize(value, expires_at)
      @value = value
      @expires_at = expires_at
    end

    def to_s
        @value
    end

    def active?
      @expires_at > Time.now
    end

    def self.generate_token(client_id, client_secret, expires=1440)
      # creates a new token that will expire in 1 day by default
      getToken = Net::HTTP.post_form URI('https://www.arcgis.com/sharing/rest/oauth2/token'),
        f: 'json',
        client_id: client_id,
        client_secret: client_secret,
        grant_type: 'client_credentials',
        expiration: expires # (minutes) max: 20160, default: 1 day

      response = JSON.parse(getToken.body)

      if response['error']
        Geocoder.log(:warn, response['error'])
      else
        token_value = response['access_token']
        expires_at = Time.now + (expires * 60)
        new(token_value, expires_at)
      end
    end
  end
end
