# frozen_string_literal: true

# Background job to forward comment webhooks to Omni-AI backend.
# Runs via Sidekiq, so it doesn't block the webhook response to Meta.

module OmniAi
  class CommentForwardJob < ApplicationJob
    queue_as :default
    retry_on StandardError, wait: 5.seconds, attempts: 3

    def perform(platform:, entries:, page_id: nil, instagram_id: nil)
      return unless OmniAi::CommentForwarder::ENABLED
      return if OmniAi::CommentForwarder::OMNI_AI_URL.blank?

      payload = {
        platform: platform,
        entries: entries,
        page_id: page_id,
        instagram_id: instagram_id,
        timestamp: Time.current.iso8601,
        source: 'chatwoot'
      }.to_json

      signature = OmniAi::CommentForwarder.compute_signature(payload)

      uri = URI(OmniAi::CommentForwarder::OMNI_AI_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.open_timeout = 10
      http.read_timeout = 15

      request = Net::HTTP::Post.new(uri.path)
      request['Content-Type'] = 'application/json'
      request['X-Omni-Signature'] = signature
      request['X-Omni-Platform'] = platform
      request['User-Agent'] = 'Chatwoot-OmniAI/1.0'
      request.body = payload

      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.error(
          "[OmniAi::CommentForwardJob] Failed to forward #{platform} comments: " \
          "HTTP #{response.code} — #{response.body&.truncate(500)}"
        )
        raise StandardError, "Omni-AI comment forward failed: HTTP #{response.code}"
      end

      Rails.logger.info(
        "[OmniAi::CommentForwardJob] Forwarded #{platform} comments (#{entries&.length || 0} entries) → HTTP #{response.code}"
      )

      # Broadcast WebSocket event so the Comments page refreshes
      broadcast_comments_update(platform, page_id, instagram_id)
    end

    private

    def broadcast_comments_update(platform, page_id, instagram_id)
      account_id = resolve_account_id(platform, page_id, instagram_id)
      return unless account_id

      ActionCable.server.broadcast(
        "account_#{account_id}",
        { event: 'omni_comments.updated', data: {} }
      )
    rescue StandardError => e
      Rails.logger.warn("[OmniAi::CommentForwardJob] broadcast error: #{e.message}")
    end

    def resolve_account_id(platform, page_id, instagram_id)
      channel = if platform == 'instagram' && instagram_id.present?
                  Channel::FacebookPage.find_by(instagram_id: instagram_id)
                elsif page_id.present?
                  Channel::FacebookPage.find_by(page_id: page_id)
                end
      channel&.account_id
    rescue StandardError
      nil
    end
  end
end
