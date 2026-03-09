class GiphyService
  include HTTParty
  base_uri 'https://api.giphy.com/v1/stickers'

  CACHE_TTL = 10.minutes
  CACHE_PREFIX = 'giphy_stickers'
  
  # Custom error classes for better error handling
  class GiphyError < StandardError; end
  class ApiKeyMissingError < GiphyError; end
  class ApiUnavailableError < GiphyError; end
  class RateLimitError < GiphyError; end
  class InvalidResponseError < GiphyError; end
  
  def initialize
    @api_key = ENV.fetch('GIPHY_API_KEY', nil)
  end

  def search_or_trending(query = nil)
    start_time = Time.current
    
    # Return empty result if API key is not configured
    unless @api_key.present?
      Rails.logger.info "GiphyService: API key not configured, returning empty result"
      return { error: 'GIPHY_API_KEY_MISSING', message: 'Giphy integration not configured', stickers: [] }
    end
    
    cache_key = generate_cache_key(query)

    result = Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
      Rails.logger.info "GiphyService: Cache miss for key #{cache_key}"
      
      if query.present?
        search(query)
      else
        trending
      end
    end
    
    result
  rescue ApiKeyMissingError => e
    Rails.logger.error "GiphyService API key missing: #{e.message}"
    { error: 'GIPHY_API_KEY_MISSING', message: 'Giphy integration not configured', stickers: [] }
  rescue RateLimitError => e
    Rails.logger.error "GiphyService rate limit exceeded: #{e.message}"
    { error: 'GIPHY_RATE_LIMIT', message: 'Too many requests to Giphy. Please try again later.', stickers: [] }
  rescue ApiUnavailableError => e
    Rails.logger.error "GiphyService API unavailable: #{e.message}"
    { error: 'GIPHY_UNAVAILABLE', message: 'Giphy service is temporarily unavailable. Please try again later.', stickers: [] }
  rescue InvalidResponseError => e
    Rails.logger.error "GiphyService invalid response: #{e.message}"
    { error: 'GIPHY_INVALID_RESPONSE', message: 'Unable to load stickers. Please try again.', stickers: [] }
  rescue StandardError => e
    Rails.logger.error "GiphyService unexpected error: #{e.message}\n#{e.backtrace.join("\n")}"
    { error: 'GIPHY_UNKNOWN_ERROR', message: 'Unable to load stickers. Please try again.', stickers: [] }
  end

  def invalidate_cache(query = nil)
    cache_key = generate_cache_key(query)
    Rails.cache.delete(cache_key)
    Rails.logger.info "GiphyService: Invalidated cache for key #{cache_key}"
  end

  def warm_cache
    # Pre-warm trending stickers cache
    Rails.logger.info "GiphyService: Warming trending stickers cache"
    search_or_trending(nil)
    
    # Pre-warm popular search terms
    popular_terms = %w[happy sad love funny cute animals]
    popular_terms.each do |term|
      Rails.logger.info "GiphyService: Warming cache for term: #{term}"
      search_or_trending(term)
    end
  end

  private

  def validate_api_key!
    raise ApiKeyMissingError, 'GIPHY_API_KEY environment variable is not set' if @api_key.blank?
  end

  def search(query)
    response = make_api_request('/search', {
      q: query,
      limit: 25,
      rating: 'g' # Only safe content
    })

    parse_giphy_response(response)
  end

  def trending
    response = make_api_request('/trending', {
      limit: 25,
      rating: 'g'
    })

    parse_giphy_response(response)
  end

  def make_api_request(endpoint, params)
    full_params = params.merge(api_key: @api_key)
    
    response = self.class.get(endpoint, {
      query: full_params,
      timeout: 10, # 10 second timeout
      headers: {
        'User-Agent' => 'Chatwoot/1.0'
      }
    })

    handle_api_response(response)
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    raise ApiUnavailableError, "Request timeout: #{e.message}"
  rescue SocketError, Errno::ECONNREFUSED => e
    raise ApiUnavailableError, "Connection failed: #{e.message}"
  rescue HTTParty::Error => e
    raise ApiUnavailableError, "HTTP error: #{e.message}"
  end

  def handle_api_response(response)
    case response.code
    when 200
      response
    when 401
      raise ApiKeyMissingError, 'Invalid or missing API key'
    when 403
      raise ApiKeyMissingError, 'API key forbidden or expired'
    when 429
      raise RateLimitError, 'Rate limit exceeded'
    when 500..599
      raise ApiUnavailableError, "Giphy server error (#{response.code})"
    else
      raise InvalidResponseError, "Unexpected response code: #{response.code}"
    end
  end

  def parse_giphy_response(response)
    parsed_body = JSON.parse(response.body)
    
    unless parsed_body.is_a?(Hash) && parsed_body.key?('data')
      raise InvalidResponseError, 'Response missing data field'
    end

    stickers = parsed_body['data'].map do |sticker_data|
      next unless sticker_data.is_a?(Hash)
      
      webp_url = sticker_data.dig('images', 'fixed_height', 'webp')
      next unless webp_url

      {
        id: sticker_data['id'],
        url: webp_url,
        alt: sticker_data['title'] || 'Giphy Sticker',
        provider: 'giphy'
      }
    end.compact

    Rails.logger.info "GiphyService: Successfully parsed #{stickers.length} stickers"
    stickers
  rescue JSON::ParserError => e
    raise InvalidResponseError, "JSON parsing failed: #{e.message}"
  end

  def generate_cache_key(query)
    normalized_query = query&.strip&.downcase || 'trending'
    "#{CACHE_PREFIX}:#{Digest::MD5.hexdigest(normalized_query)}"
  end


end