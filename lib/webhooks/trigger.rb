class Webhooks::Trigger
  def self.execute(url, payload)
    RestClient.post(url, payload.to_json, { content_type: :json, accept: :json })
  rescue StandardError => e
    Raven.capture_exception(e)
  end
end
