# Searches Giphy with the installation's API key so it never reaches the browser.
# A blank query returns trending GIFs, which the picker shows before the agent types.
class Integrations::Giphy::SearchService
  API_URL = 'https://api.giphy.com/v1/gifs'.freeze
  RESULTS_PER_PAGE = 24
  # Replies go to customers, so keep results suitable for all audiences.
  RATING = 'g'.freeze

  def self.enabled?
    api_key.present?
  end

  def self.api_key
    GlobalConfigService.load('GIPHY_API_KEY', nil)
  end

  def initialize(query:, offset: 0)
    @query = query.to_s.strip
    @offset = offset.to_i
  end

  def perform
    response = HTTParty.get(
      "#{API_URL}/#{@query.present? ? 'search' : 'trending'}",
      query: { api_key: self.class.api_key, q: @query.presence, limit: RESULTS_PER_PAGE, offset: @offset, rating: RATING }.compact,
      timeout: 10
    )
    raise CustomExceptions::GiphyRequestFailed, response.code unless response.success?

    {
      gifs: response.parsed_response['data'].map { |gif| serialize(gif) },
      next_offset: next_offset(response.parsed_response['pagination'])
    }
  end

  private

  def serialize(gif)
    preview = gif.dig('images', 'fixed_width')
    {
      id: gif['id'],
      title: gif['title'],
      preview_url: preview['url'],
      width: preview['width'].to_i,
      height: preview['height'].to_i,
      # `downsized` stays under 2MB, which fits the attachment limits of most channels.
      url: gif.dig('images', 'downsized', 'url')
    }
  end

  def next_offset(pagination)
    offset = pagination['offset'] + pagination['count']
    offset if offset < pagination['total_count']
  end
end
