class Webhooks::Trigger
  def self.execute(url, payload)
    RestClient::Request.execute(
      method: :post,
      url: url, payload: payload.to_json,
      headers: { content_type: :json, accept: :json },
      timeout: 5
    )
  rescue *ExceptionList::REST_CLIENT_EXCEPTIONS, *ExceptionList::URI_EXCEPTIONS => e
    Rails.logger.info "Exception: invalid webhook url #{url} : #{e.message}"
  rescue StandardError => e
    Raven.capture_exception(e)
  end
end
