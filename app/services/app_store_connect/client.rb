class AppStoreConnect::Client
  class Error < StandardError; end

  pattr_initialize [:channel!]

  def fetch_app
    get("/v1/apps/#{channel.app_id}")['data']
  end

  def fetch_reviews(since: nil)
    reviews = []
    next_url = nil

    loop do
      payload = next_url ? get_url(next_url) : get(reviews_path, reviews_query)
      included = Array(payload['included'])
      review_payloads = Array(payload['data']).map { |review| normalize_review(review, included) }
      fresh_payloads = fresh_review_payloads(review_payloads, since)
      reviews.concat(fresh_payloads)

      next_url = payload.dig('links', 'next')
      break if next_url.blank?
    end

    reviews
  end

  def create_review_response(review_id, response_body)
    create_or_update_review_response(review_id, response_body)
  end

  def create_or_update_review_response(review_id, response_body)
    post('/v1/customerReviewResponses', review_response_payload(review_id, response_body))['data']
  end

  private

  def reviews_path
    "/v1/apps/#{channel.app_id}/customerReviews"
  end

  def reviews_query
    {
      include: 'response',
      limit: Channel::AppStore::REVIEWS_PAGE_SIZE,
      sort: '-createdDate'
    }
  end

  def normalize_review(review, included)
    response_id = review.dig('relationships', 'response', 'data', 'id')
    response = included.find { |item| item['type'] == 'customerReviewResponses' && item['id'] == response_id }

    {
      'review' => review,
      'response' => response
    }
  end

  def fresh_review_payloads(review_payloads, since)
    return review_payloads if since.blank?

    review_payloads.select { |review_payload| review_updated_after?(review_payload, since) }
  end

  def review_updated_after?(review_payload, since)
    review_updated_at = [
      parsed_timestamp(review_payload.dig('review', 'attributes', 'createdDate')),
      parsed_timestamp(review_payload.dig('response', 'attributes', 'lastModifiedDate'))
    ].compact.max

    return true if review_updated_at.blank?

    review_updated_at >= since
  end

  def parsed_timestamp(value)
    Time.zone.parse(value.to_s)
  rescue StandardError
    nil
  end

  def get(path, query = {})
    request(:get, "#{Channel::AppStore::API_BASE_URL}#{path}", query: query)
  end

  def get_url(url)
    request(:get, url)
  end

  def post(path, body)
    request(:post, "#{Channel::AppStore::API_BASE_URL}#{path}", body: body)
  end

  def request(method, url, query: {}, body: nil)
    response = HTTParty.public_send(
      method,
      url,
      headers: headers,
      query: query,
      body: body&.to_json
    )

    log_rate_limit(response)
    return response.parsed_response if response.success?

    raise Error, error_message(response)
  end

  def headers
    {
      'Authorization' => "Bearer #{token}",
      'Content-Type' => 'application/json'
    }
  end

  def token
    AppStoreConnect::TokenService.new(channel: channel).token
  end

  def review_response_payload(review_id, response_body)
    {
      data: {
        type: 'customerReviewResponses',
        attributes: {
          responseBody: response_body.to_s
        },
        relationships: {
          review: {
            data: {
              type: 'customerReviews',
              id: review_id
            }
          }
        }
      }
    }
  end

  def log_rate_limit(response)
    rate_limit = response.headers['x-rate-limit']
    Rails.logger.debug { "[APP_STORE_CONNECT] rate_limit=#{rate_limit}" } if rate_limit.present?
  end

  def error_message(response)
    parsed_response = response.parsed_response
    errors = parsed_response.is_a?(Hash) ? parsed_response['errors'] : []
    details = Array(errors).filter_map { |error| error['detail'] || error['title'] }.join(', ')
    details = response.body if details.blank?
    "App Store Connect API failed (#{response.code}): #{details}"
  end
end
