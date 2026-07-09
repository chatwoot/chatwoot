require 'json'
require 'uri'

class Autonomia::Prospecting::Providers::GooglePlacesProvider
  ENDPOINT = 'https://places.googleapis.com/v1/places:searchText'.freeze
  FIELD_MASK = [
    'places.id',
    'places.displayName',
    'places.formattedAddress',
    'places.location',
    'places.rating',
    'places.userRatingCount',
    'places.types',
    'places.nationalPhoneNumber',
    'places.internationalPhoneNumber',
    'places.websiteUri',
    'places.photos',
    'places.currentOpeningHours.openNow',
    'places.currentOpeningHours.weekdayDescriptions',
    'places.regularOpeningHours.weekdayDescriptions'
  ].join(',').freeze

  attr_reader :api_units

  def initialize(query:, location:, radius:, area_type: 'radius', area_config: {}, limit:, api_key:)
    @query = query.to_s.strip
    @location = location.to_s.strip
    @radius = radius.to_i
    @area_type = area_type.to_s
    @area_config = area_config.to_h.deep_stringify_keys
    @limit = limit.to_i
    @api_key = api_key.to_s
    @api_units = 0
  end

  def search
    response = HTTParty.post(
      ENDPOINT,
      body: request_body.to_json,
      headers: headers,
      timeout: 10
    )
    @api_units = 1

    raise provider_error(response) unless response.success?

    Array(JSON.parse(response.body)['places']).first(@limit).map { |place| lead_for(place) }
  rescue JSON::ParserError
    raise Autonomia::Prospecting::SearchRunner::ProviderError, 'Google Places returned an invalid response'
  rescue HTTParty::Error, SocketError, Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED => e
    raise Autonomia::Prospecting::SearchRunner::ProviderError, "Google Places request failed: #{e.message}"
  end

  private

  def request_body
    {
      textQuery: [@query, @location].compact_blank.join(' '),
      maxResultCount: [@limit, 20].min,
      languageCode: 'pt-BR',
      regionCode: 'BR'
    }.merge(location_bias_payload)
  end

  def location_bias_payload
    rectangle = rectangle_bias
    return { locationBias: { rectangle: rectangle } } if rectangle.present?

    circle = circle_bias
    return { locationBias: { circle: circle } } if circle.present?

    {}
  end

  def rectangle_bias
    return unless @area_type == 'viewport'

    bounds = @area_config['bounds']
    return if bounds.blank?

    {
      low: {
        latitude: bounds['south'].to_f,
        longitude: bounds['west'].to_f
      },
      high: {
        latitude: bounds['north'].to_f,
        longitude: bounds['east'].to_f
      }
    }
  end

  def circle_bias
    center = @area_config['center']
    return if center.blank?

    {
      center: {
        latitude: center['lat'].to_f,
        longitude: center['lng'].to_f
      },
      radius: [@radius, 50_000].min
    }
  end

  def headers
    {
      'Content-Type' => 'application/json',
      'X-Goog-Api-Key' => @api_key,
      'X-Goog-FieldMask' => FIELD_MASK
    }
  end

  def provider_error(response)
    body = JSON.parse(response.body) rescue {}
    message = body.dig('error', 'message').presence || "Google Places returned HTTP #{response.code}"
    Autonomia::Prospecting::SearchRunner::ProviderError.new(message)
  end

  def lead_for(place)
    address = place['formattedAddress'].to_s
    {
      provider: 'google_places',
      provider_place_id: place['id'],
      name: place.dig('displayName', 'text').presence || 'Google Places lead',
      phone: place['internationalPhoneNumber'].presence || place['nationalPhoneNumber'],
      website: place['websiteUri'],
      address: address,
      city: city_from(address),
      state: state_from(address),
      country: 'BR',
      latitude: place.dig('location', 'latitude'),
      longitude: place.dig('location', 'longitude'),
      rating: place['rating'],
      reviews_count: place['userRatingCount'],
      category: Array(place['types']).first,
      raw_payload: place
    }
  end

  def city_from(address)
    city_state_match(address)&.[](1)&.strip
  end

  def state_from(address)
    city_state_match(address)&.[](2)
  end

  def city_state_match(address)
    address.match(/,\s*([^,]+?)\s*-\s*([A-Z]{2})\b/)
  end
end
