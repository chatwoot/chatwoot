class Apify::Client
  include HTTParty

  BASE_URI = 'https://api.apify.com/v2'.freeze
  ACTOR_ID = 'apify~instagram-profile-scraper'.freeze
  DEFAULT_TIMEOUT = 120

  class ApiError < StandardError
    attr_reader :code, :response

    def initialize(message = nil, code = nil, response = nil)
      @code = code
      @response = response
      super(message)
    end
  end

  def initialize(api_token: ENV.fetch('APIFY_API_TOKEN'))
    @api_token = api_token
  end

  # Run the Instagram Profile Scraper for given usernames and wait for results.
  # Returns an array of profile data hashes.
  def scrape_profiles(usernames)
    run = start_run(usernames: Array(usernames))
    dataset_id = run['defaultDatasetId']
    raise ApiError.new('No dataset returned from Apify run', nil, run) if dataset_id.blank?

    fetch_dataset_items(dataset_id)
  end

  private

  def start_run(input)
    url = "#{BASE_URI}/acts/#{ACTOR_ID}/runs"
    response = self.class.post(
      url,
      query: { token: @api_token, waitForFinish: DEFAULT_TIMEOUT },
      headers: { 'Content-Type' => 'application/json' },
      body: input.to_json,
      timeout: DEFAULT_TIMEOUT + 10
    )
    handle_response(response)['data']
  end

  def fetch_dataset_items(dataset_id)
    url = "#{BASE_URI}/datasets/#{dataset_id}/items"
    response = self.class.get(url, query: { token: @api_token })
    handle_response(response)
  end

  def handle_response(response)
    case response.code
    when 200..299
      response.parsed_response
    when 402
      raise ApiError.new('Apify account has insufficient credits', response.code, response)
    when 429
      raise ApiError.new('Apify rate limit exceeded', response.code, response)
    else
      error_message = "Apify API error: #{response.code} - #{response.body&.truncate(500)}"
      Rails.logger.error("[Apify::Client] #{error_message}")
      raise ApiError.new(error_message, response.code, response)
    end
  end
end
