# frozen_string_literal: true

# POST /api/v1/omni_ai/comment_reply
#
# Called by omni-ai backend to post an AI-generated reply to an Instagram or
# Facebook comment. Uses the access_token stored in Chatwoot's inbox channel,
# so the token is never exposed to the omni-ai process.
#
# Auth:   Authorization: Bearer {OMNI_AI_WEBHOOK_TOKEN}
# Body:   inbox_id, comment_id, reply_text, platform ("instagram" | "facebook")

class OmniAi::CommentRepliesController < ActionController::API
  include OmniAi::InboxResolver

  IG_GRAPH_BASE = 'https://graph.instagram.com/v22.0'
  FB_GRAPH_BASE = 'https://graph.facebook.com/v22.0'

  before_action :verify_token

  def create
    comment_id = params[:comment_id].to_s.strip
    reply_text = params[:reply_text].to_s.strip
    platform   = params[:platform].to_s.downcase.presence || 'instagram'

    if comment_id.blank? || reply_text.blank?
      return render json: { error: 'comment_id and reply_text are required' }, status: :bad_request
    end

    inbox = resolve_inbox
    return render json: { error: 'inbox not found' }, status: :not_found unless inbox

    access_token = resolve_access_token(inbox)
    unless access_token.present?
      return render json: { error: 'inbox channel has no access_token' }, status: :unprocessable_entity
    end

    graph_base = platform == 'facebook' ? FB_GRAPH_BASE : IG_GRAPH_BASE
    # Instagram: POST /{comment-id}/replies
    # Facebook:  POST /{comment-id}/comments
    action = platform == 'facebook' ? 'comments' : 'replies'

    response = HTTParty.post(
      "#{graph_base}/#{comment_id}/#{action}",
      query: { message: reply_text, access_token: access_token }
    )

    if response.success?
      Rails.logger.info("[OmniAi] comment_reply posted: comment=#{comment_id} platform=#{platform}")
      render json: { success: true, id: response.parsed_response['id'] }, status: :ok
    else
      Rails.logger.warn("[OmniAi] comment_reply Graph API error: #{response.code} #{response.body}")
      render json: { error: response.parsed_response, code: response.code }, status: :unprocessable_entity
    end
  end

  private

  def verify_token
    expected = ENV.fetch('OMNI_AI_WEBHOOK_TOKEN', '')
    actual   = request.headers['Authorization'].to_s.delete_prefix('Bearer ').strip
    return head :unauthorized unless expected.present?
    return head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(actual, expected)
  end

  def resolve_access_token(inbox)
    channel = inbox.channel
    return nil unless channel

    if channel.respond_to?(:page_access_token)
      channel.page_access_token
    elsif channel.respond_to?(:access_token)
      channel.access_token
    end
  end
end
