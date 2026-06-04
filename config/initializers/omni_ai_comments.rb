# frozen_string_literal: true

# ═══════════════════════════════════════════════════════════════════════════════
# Omni-AI Comment Forwarding — Monkey Patch
# ═══════════════════════════════════════════════════════════════════════════════
#
# This initializer intercepts Facebook (feed/comments) and Instagram (comments)
# webhook events and forwards them to the Omni-AI backend for AI-powered
# comment replies + DM follow-ups.
#
# All existing Chatwoot flows (DMs, deliveries, reads, echoes) are UNTOUCHED.
# Only comment-type events are forwarded.
#
# ENV vars required:
#   OMNI_AI_COMMENTS_URL   — e.g. https://ai.shoev.co.il/webhooks/meta-comments
#   OMNI_AI_COMMENTS_SECRET — shared HMAC secret for request signing
#   OMNI_AI_COMMENTS_ENABLED — "true" to enable (default: "false")
#
# Safe for Chatwoot upgrades: uses alias_method to preserve original behavior.
# ═══════════════════════════════════════════════════════════════════════════════

module OmniAi
  module CommentForwarder
    OMNI_AI_URL    = ENV.fetch('OMNI_AI_COMMENTS_URL', '').freeze
    OMNI_AI_SECRET = ENV.fetch('OMNI_AI_COMMENTS_SECRET', '').freeze
    ENABLED        = ENV.fetch('OMNI_AI_COMMENTS_ENABLED', 'false') == 'true'

    # Forward comment entries to Omni-AI backend via background job
    def self.forward(platform:, entries:, page_id: nil, instagram_id: nil)
      unless ENABLED
        Rails.logger.warn("[OmniAi::CommentForwarder] Skipped #{platform} comment forwarding: OMNI_AI_COMMENTS_ENABLED=false")
        return { enqueued: false, reason: 'disabled' }
      end

      if OMNI_AI_URL.blank?
        Rails.logger.warn("[OmniAi::CommentForwarder] Skipped #{platform} comment forwarding: OMNI_AI_COMMENTS_URL is blank")
        return { enqueued: false, reason: 'missing_url' }
      end

      if OMNI_AI_SECRET.blank?
        Rails.logger.warn("[OmniAi::CommentForwarder] Skipped #{platform} comment forwarding: OMNI_AI_COMMENTS_SECRET is blank")
        return { enqueued: false, reason: 'missing_secret' }
      end

      if entries.blank?
        Rails.logger.warn("[OmniAi::CommentForwarder] Skipped #{platform} comment forwarding: entries are blank")
        return { enqueued: false, reason: 'blank_entries' }
      end

      OmniAi::CommentForwardJob.perform_later(
        platform: platform,
        entries: entries,
        page_id: page_id,
        instagram_id: instagram_id
      )

      Rails.logger.info(
        "[OmniAi::CommentForwarder] Enqueued #{platform} comment forward " \
        "(entries=#{entries.length}, url_set=#{OMNI_AI_URL.present?}, secret_set=#{OMNI_AI_SECRET.present?})"
      )
      { enqueued: true, reason: 'enqueued' }
    end

    # Detect if an entry array contains comment events (FB feed or IG comments)
    def self.contains_fb_comments?(entries)
      return false unless entries.is_a?(Array)

      entries.any? do |entry|
        changes = entry[:changes] || entry['changes'] || []
        changes.any? do |change|
          field = change[:field] || change['field']
          value = change[:value] || change['value'] || {}
          item  = value[:item] || value['item']

          field == 'feed' && item == 'comment'
        end
      end
    end

    def self.contains_ig_comments?(entries)
      return false unless entries.is_a?(Array)

      entries.any? do |entry|
        changes = entry[:changes] || entry['changes'] || []
        changes.any? do |change|
          field = change[:field] || change['field']
          field == 'comments'
        end
      end
    end

    # Extract page_id / instagram_id from entry
    def self.extract_page_id(entries)
      entries&.first&.dig(:id) || entries&.first&.dig('id')
    end

    # Sign the payload with HMAC-SHA256 for verification
    def self.compute_signature(payload_json)
      OpenSSL::HMAC.hexdigest('SHA256', OMNI_AI_SECRET, payload_json)
    end
  end
end
