class Webhooks::Trigger
  def self.execute(url, payload)
    response = RestClient::Request.execute(
      method: :post,
      url: url, payload: payload.to_json,
      headers: { content_type: :json, accept: :json },
      timeout: 5
    )
    Rails.logger.info "Performed Request:  Code - #{response.code}"
  rescue StandardError => e
    Rails.logger.warn "Exception: invalid webhook url #{url} : #{e.message}"
  end
end
