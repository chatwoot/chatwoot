# frozen_string_literal: true

# ═══════════════════════════════════════════════════════════════════════════════
# Rack middleware to intercept Facebook Page webhook POST /bot requests
# that contain comment events (field='feed', item='comment').
#
# The facebook-messenger gem only processes `messaging[]` entries and ignores
# `changes[]` entries. This middleware taps into the raw request body,
# detects comment payloads, and forwards them to Omni-AI — BEFORE the gem
# processes it. The original request continues unmodified.
#
# Insert BEFORE the Facebook::Messenger::Server mount in the middleware stack.
# ═══════════════════════════════════════════════════════════════════════════════

module OmniAi
  class FacebookCommentMiddleware
    BOT_PATH = '/bot'

    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)

      # Only intercept POST /bot with JSON body
      if request.post? && request.path == BOT_PATH && json_content?(request)
        body = read_body(request)
        if body.present?
          begin
            payload = JSON.parse(body).with_indifferent_access
            Rails.logger.info("[OmniAi::FB][DEBUG] RAW PAYLOAD: #{body}")
            Rails.logger.info("[OmniAi::FB] POST /bot received, object=#{payload[:object]}, entries=#{payload[:entry]&.size}")
            if payload[:object] == 'page' && comment_entries?(payload[:entry])
              page_id = payload[:entry]&.first&.dig(:id)
              result = OmniAi::CommentForwarder.forward(
                platform: 'facebook',
                entries: payload[:entry].as_json,
                page_id: page_id
              )
              if result[:enqueued]
                Rails.logger.info("[OmniAi] Enqueued Facebook comment webhook forward (page_id=#{page_id})")
              else
                Rails.logger.warn("[OmniAi] Skipped Facebook comment webhook forward (page_id=#{page_id}, reason=#{result[:reason]})")
              end
            elsif payload[:object] == 'page'
              fields = payload[:entry]&.flat_map { |e| (e[:changes] || e['changes'] || []).map { |c| c[:field] || c['field'] } }
              # Debug: log full changes to see item/verb values
              payload[:entry]&.each_with_index do |entry, idx|
                Rails.logger.info("[OmniAi::FB][DEBUG] ENTRY[#{idx}]: #{entry}")
                (entry[:changes] || entry['changes'] || []).each_with_index do |change, cidx|
                  value = change[:value] || change['value'] || {}
                  Rails.logger.info("[OmniAi::FB][DEBUG] ENTRY[#{idx}].CHANGE[#{cidx}]: #{change}")
                  Rails.logger.info("[OmniAi::FB] feed change detail — field=#{change[:field]||change['field']} item=#{value[:item]||value['item']} verb=#{value[:verb]||value['verb']} keys=#{value.keys}")
                end
              end
              Rails.logger.info("[OmniAi::FB] Page webhook but not a comment. Fields: #{fields}")
            end
          rescue JSON::ParserError => e
            Rails.logger.warn("[OmniAi::FacebookCommentMiddleware] JSON parse error: #{e.message}")
          end
        end
      end

      # Always pass through to the original handler
      @app.call(env)
    end

    private

    def json_content?(request)
      ct = request.content_type.to_s.downcase
      ct.include?('application/json') || ct.include?('text/json')
    end

    def read_body(request)
      body = request.body.read
      request.body.rewind # Rewind so downstream can read it again
      body
    end

    def comment_entries?(entries)
      return false unless entries.is_a?(Array)

      entries.any? do |entry|
        changes = entry[:changes] || entry['changes'] || []
        changes.any? do |change|
          field = change[:field] || change['field']
          value = change[:value] || change['value'] || {}
          item = value[:item] || value['item']
          field.to_s == 'feed' && item.to_s == 'comment'
        end
      end
    end
  end
end
