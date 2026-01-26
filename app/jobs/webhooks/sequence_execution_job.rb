class Webhooks::SequenceExecutionJob < ApplicationJob
  queue_as :integrations

  def perform(url, method, headers, payload)
    response = HTTParty.send(
      method.downcase.to_sym,
      url,
      headers: headers,
      body: payload.to_json,
      timeout: 10 # 10s timeout
    )

    unless response.success?
      raise "Webhook failed: #{response.code} - #{response.body}"
    end
  rescue StandardError => e
    Rails.logger.error "Sequence Webhook Failed: #{e.message}"
    raise e # Re-raise to trigger Sidekiq retry logic
  end
end
