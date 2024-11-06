class Evolution::Api
  def initialize(path, payload, method = :post)
    @path = path
    @method = method
    @url = ENV.fetch('EVOLUTION_API_URL', nil)
    @token = ENV.fetch('EVOLUTION_API_KEY', nil)
    @payload = payload
  end

  def call
    perform_request
  end

  private

  def perform_request
    byebug
    response = RestClient::Request.execute(
      method: @method,
      url: "#{@url}/#{@path}",
      payload: @payload.to_json,
      headers: {
        content_type: :json,
        accept: :json,
        apikey: @token
      },
      timeout: 15
    )

    JSON.parse(response.body)
  end
end
