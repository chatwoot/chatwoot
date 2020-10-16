class Webhooks::Trigger
  def self.execute(url, payload)
    RestClient.post(url, payload.to_json, { content_type: :json, accept: :json })
  rescue *ExceptionList::REST_CLIENT_EXCEPTIONS, *ExceptionList::URI_EXCEPTIONS => e
    Rails.logger.info "Exception: invalid webhook url #{url} : #{e.message}"
  rescue StandardError => e
    Raven.capture_exception(e)
  end
end
