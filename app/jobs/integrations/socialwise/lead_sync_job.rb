# frozen_string_literal: true

class Integrations::Socialwise::LeadSyncJob < ApplicationJob
  queue_as :medium

  TIMEOUT = 15
  ROUTE_PATH = '/api/admin/leads-chatwit/recebearquivos'

  def perform(payload)
    endpoint = ENV.fetch('SOCIALWISE_WEBHOOK_URL', nil)
    if endpoint.blank?
      Rails.logger.warn '[SOCIALWISE-LEAD-SYNC] SOCIALWISE_WEBHOOK_URL not configured. Skipping dispatch.'
      return
    end

    response = HTTParty.post(
      "#{normalized_endpoint(endpoint)}#{ROUTE_PATH}",
      headers: request_headers,
      body: payload.to_json,
      timeout: TIMEOUT
    )

    if response.success?
      Rails.logger.info(
        "[SOCIALWISE-LEAD-SYNC] Delivered event=#{payload[:event] || payload['event']} status=#{response.code}"
      )
    else
      Rails.logger.error(
        "[SOCIALWISE-LEAD-SYNC] Delivery failed event=#{payload[:event] || payload['event']} status=#{response.code} body=#{response.body.to_s.truncate(500)}"
      )
    end
  rescue StandardError => e
    Rails.logger.error "[SOCIALWISE-LEAD-SYNC] Failed to deliver payload: #{e.class}: #{e.message}"
  end

  private

  def request_headers
    headers = { 'Content-Type' => 'application/json' }
    secret = ENV.fetch('CHATWIT_WEBHOOK_SECRET', nil)
    headers['X-Chatwit-Secret'] = secret if secret.present?
    headers
  end

  def normalized_endpoint(endpoint)
    endpoint.to_s.chomp('/')
  end
end
