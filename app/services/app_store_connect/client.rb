class AppStoreConnect::Client
  class Error < StandardError; end

  pattr_initialize [:channel!]

  def fetch_app
    get("/v1/apps/#{channel.app_id}")['data']
  end

  def fetch_reviews
    reviews = []
    next_url = nil

    loop do
      payload = next_url ? get_url(next_url) : get(reviews_path, reviews_query)
      included = Array(payload['included'])
      reviews.concat(Array(payload['data']).map { |review| normalize_review(review, included) })

      next_url = payload.dig('links', 'next')
      break if next_url.blank?
    end

    reviews
  end

  def create_review_response(review_id, response_body)
    post('/v1/customerReviewResponses', review_response_payload(review_id, response_body))['data']
  end

  def update_review_response(response_id, response_body)
    patch("/v1/customerReviewResponses/#{response_id}", review_response_update_payload(response_id, response_body))['data']
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

  def get(path, query = {})
    request(:get, "#{Channel::AppStore::API_BASE_URL}#{path}", query: query)
  end

  def get_url(url)
    request(:get, url)
  end

  def post(path, body)
    request(:post, "#{Channel::AppStore::API_BASE_URL}#{path}", body: body)
  end

  def patch(path, body)
    request(:patch, "#{Channel::AppStore::API_BASE_URL}#{path}", body: body)
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
    @token ||= AppStoreConnect::TokenService.new(channel: channel).token
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

  def review_response_update_payload(response_id, response_body)
    {
      data: {
        type: 'customerReviewResponses',
        id: response_id,
        attributes: {
          responseBody: response_body.to_s
        }
      }
    }
  end

  def log_rate_limit(response)
    rate_limit = response.headers['x-rate-limit']
    Rails.logger.info("[APP_STORE_CONNECT] rate_limit=#{rate_limit}") if rate_limit.present?
  end

  def error_message(response)
    parsed_response = response.parsed_response
    errors = parsed_response.is_a?(Hash) ? parsed_response['errors'] : []
    details = Array(errors).filter_map { |error| error['detail'] || error['title'] }.join(', ')
    details = response.body if details.blank?
    "App Store Connect API failed (#{response.code}): #{details}"
  end
end
