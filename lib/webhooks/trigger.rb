class Webhooks::Trigger
  def self.execute(url, payload)
    RestClient.post(url, payload)
  rescue StandardError => e
    Raven.capture_exception(e)
  end
end
