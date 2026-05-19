require 'net/http'
require 'uri'
require 'json'

# Sister job to MarketingTemplatePatchJob: when an incoming message in the
# Comments inbox (Channel::Api) lands with NULL content OR with only the
# "📎 البوست:" suffix and no comment text (because n8n WF1 couldn't extract
# comment text from the Meta webhook), fetch the text via the dashboard
# /api/admin/resolve-comment endpoint and patch the message.
class CommentTextPatchJob < ApplicationJob
  queue_as :low

  RESOLVE_URL = 'https://api.eltafouk.com/app/api/admin/resolve-comment'.freeze
  RETRY_DELAYS = [3, 15, 60].freeze
  POST_LINK_MARKER = '📎 البوست:'.freeze

  def perform(message_id, attempt = 0)
    m = Message.find_by(id: message_id)
    return unless m
    return if text_part_present?(m)
    return unless candidate?(m)

    secret = ENV['MARKETING_RESOLVE_SECRET'].to_s
    return Rails.logger.warn('[cmt-patch] no MARKETING_RESOLVE_SECRET') if secret.empty?

    conv = m.conversation
    ca = conv.custom_attributes || {}
    comment_id = ca['comment_id'].to_s
    post_id    = ca['post_id'].to_s
    if comment_id.empty? || post_id.empty?
      Rails.logger.info("[cmt-patch] msg=#{message_id} skipped: missing custom_attributes")
      return
    end
    page_id = post_id.split('_').first
    if page_id.to_s.empty?
      Rails.logger.info("[cmt-patch] msg=#{message_id} skipped: cannot derive page_id from post_id=#{post_id}")
      return
    end

    res = post_json(RESOLVE_URL, { comment_id: comment_id, page_id: page_id, post_id: post_id }, secret)
    if res.nil? || !res['ok']
      err = res && res['error']
      if attempt < RETRY_DELAYS.length && transient?(err)
        self.class.set(wait: RETRY_DELAYS[attempt].seconds).perform_later(message_id, attempt + 1)
      else
        Rails.logger.info("[cmt-patch] msg=#{message_id} skipped: #{err.inspect}")
      end
      return
    end

    text = res['message'].to_s.strip
    return if text.empty?

    post_url = (res['post_url'] || ca['post_url']).to_s
    new_content = post_url.empty? ? text : "#{text}\n\n#{POST_LINK_MARKER} #{post_url}"
    m.update!(content: new_content)
    Rails.logger.info("[cmt-patch] msg=#{message_id} patched (len=#{text.length})")
  rescue StandardError => e
    Rails.logger.error("[cmt-patch] msg=#{message_id} error: #{e.class}: #{e.message}")
  end

  private

  def text_part_present?(m)
    return false if m.content.blank?

    !m.content.to_s.split(POST_LINK_MARKER).first.to_s.strip.empty?
  end

  def candidate?(m)
    m.message_type == 'incoming' &&
      m.inbox&.channel_type == 'Channel::Api' &&
      m.conversation&.custom_attributes&.dig('comment_id').to_s.present?
  end

  def transient?(err)
    s = err.to_s
    s.include?('does not exist') || s.include?('timed out') || s.include?('graph_5')
  end

  def post_json(url, body, secret)
    uri = URI(url)
    req = Net::HTTP::Post.new(uri)
    req['Authorization'] = "Bearer #{secret}"
    req['Content-Type']  = 'application/json'
    req.body = body.to_json
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.read_timeout = 15
    http.open_timeout = 5
    res = http.request(req)
    begin
      JSON.parse(res.body)
    rescue StandardError
      nil
    end
  end
end
