class Webhooks::Trigger
  def self.execute(url, payload, method = :post, headers = { content_type: :json, accept: :json })
    response = RestClient::Request.execute(
      method: method,
      url: url,
      payload: payload.to_json,
      headers: headers,
      timeout: 5
    )
    Rails.logger.info "Performed Request:  Code - #{response.code}"
  rescue *ExceptionList::REST_CLIENT_EXCEPTIONS, URI::InvalidURIError => e
    Rails.logger.error "Exception: invalid webhook url #{url} : #{e.message}"
  rescue StandardError => e
    Rails.logger.error "Exception: invalid webhook url #{url} : #{e.message}"
    ChatwootExceptionTracker.new(e).capture_exception
  end
end
