require 'digest'

class Autonomia::Prospecting::Providers::MockProvider
  CATEGORIES = [
    'Clinica',
    'Consultoria',
    'Comercio',
    'Servico local',
    'Industria',
    'Educacao'
  ].freeze

  STREETS = [
    'Rua das Flores',
    'Avenida Brasil',
    'Rua XV de Novembro',
    'Avenida Paulista',
    'Rua Sete de Setembro',
    'Alameda Santos'
  ].freeze

  def initialize(query:, location:, radius:, area_type: 'radius', area_config: {}, limit:)
    @query = query.to_s.strip
    @location = location.to_s.strip
    @radius = radius.to_i
    @area_type = area_type.to_s
    @area_config = area_config.to_h.deep_stringify_keys
    @limit = limit.to_i
  end

  def search
    return [] if @query.blank?
    return [] if empty_query?

    Array.new(@limit) { |index| lead_for(index) }
  end

  private

  def empty_query?
    normalized_query = @query.downcase
    normalized_query.include?('empty') ||
      normalized_query.include?('vazio') ||
      normalized_query.include?('sem resultados')
  end

  def lead_for(index)
    seed = Digest::SHA256.hexdigest([@query.downcase, @location.downcase, @radius, index].join(':'))
    city, state = location_parts
    category = CATEGORIES[seed[0..1].to_i(16) % CATEGORIES.size]
    name = "#{business_prefix(index)} #{@query.titleize}"
    phone_suffix = seed[2..9].to_i(16).to_s.rjust(8, '0')[-8, 8]

    {
      provider: 'mock',
      provider_place_id: "mock_#{seed[0..15]}",
      name: name,
      phone: "+55 11 9#{phone_suffix}",
      website: "https://#{slug(name)}.example.com",
      address: address_for(seed),
      city: city,
      state: state,
      country: 'BR',
      latitude: latitude(seed),
      longitude: longitude(seed),
      rating: rating(seed),
      reviews_count: seed[21..24].to_i(16) % 450,
      category: category,
      raw_payload: {
        mock_seed: seed,
        query: @query,
        location: @location,
        radius: @radius,
        photos: mock_photos(seed),
        currentOpeningHours: {
          openNow: seed[25..26].to_i(16).even?
        }
      }
    }
  end

  def business_prefix(index)
    [
      'Alpha',
      'Norte',
      'Prime',
      'Central',
      'Nova',
      'Atlas',
      'Viva',
      'Ponto'
    ][index % 8]
  end

  def address_for(seed)
    street = STREETS[seed[10..11].to_i(16) % STREETS.size]
    number = seed[12..14].to_i(16) % 900 + 100
    "#{street}, #{number}"
  end

  def location_parts
    city, state = @location.split(',', 2).map { |part| part.to_s.strip }
    [city.presence || 'Sao Paulo', state.presence || 'SP']
  end

  def latitude(seed)
    return viewport_coordinate(seed, 'lat') if viewport_bounds?

    center = configured_center
    return radial_coordinate(seed, center, :lat) if center.present?

    (-23.7 + (seed[15..18].to_i(16) % 5000) / 10_000.0).round(6)
  end

  def longitude(seed)
    return viewport_coordinate(seed, 'lng') if viewport_bounds?

    center = configured_center
    return radial_coordinate(seed, center, :lng) if center.present?

    (-46.8 + (seed[19..22].to_i(16) % 5000) / 10_000.0).round(6)
  end

  def rating(seed)
    (3.5 + (seed[23..24].to_i(16) % 16) / 10.0).round(2)
  end

  def mock_photos(seed)
    return [] unless seed[27..28].to_i(16).even?

    [{ name: "mock_photo_#{seed[0..7]}" }]
  end

  def slug(value)
    value.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/\A-|-+\z/, '')
  end

  def viewport_bounds?
    @area_type == 'viewport' && @area_config['bounds'].present?
  end

  def viewport_coordinate(seed, axis)
    bounds = @area_config['bounds']
    if axis == 'lat'
      ratio = (seed[15..18].to_i(16) % 10_000) / 10_000.0
      return (bounds['south'].to_f + ((bounds['north'].to_f - bounds['south'].to_f) * ratio)).round(6)
    end

    ratio = (seed[19..22].to_i(16) % 10_000) / 10_000.0
    (bounds['west'].to_f + ((bounds['east'].to_f - bounds['west'].to_f) * ratio)).round(6)
  end

  def configured_center
    center = @area_config['center']
    return if center.blank?

    { lat: center['lat'].to_f, lng: center['lng'].to_f }
  end

  def radial_coordinate(seed, center, axis)
    radius_degrees = [[@radius.to_f / 111_000.0, 0.01].max, 0.45].min
    ratio = axis == :lat ? seed[15..18].to_i(16) : seed[19..22].to_i(16)
    offset = ((ratio % 10_000) / 10_000.0) - 0.5
    base = axis == :lat ? center[:lat] : center[:lng]

    (base + (offset * radius_degrees * 2)).round(6)
  end
end
