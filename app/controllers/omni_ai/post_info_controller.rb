# frozen_string_literal: true

# GET /api/v1/omni_ai/post_info
#
# Fetches Facebook/Instagram post metadata from the Graph API using the
# page access token stored in Chatwoot's inbox channel.
#
# Auth:   Authorization: Bearer {OMNI_AI_WEBHOOK_TOKEN}
# Params: inbox_id, post_id, platform ("facebook" | "instagram")

class OmniAi::PostInfoController < ActionController::API
  include OmniAi::InboxResolver

  FB_GRAPH_BASE = 'https://graph.facebook.com/v22.0'
  IG_GRAPH_BASE = 'https://graph.instagram.com/v22.0'

  before_action :verify_token

  def show
    post_id  = params[:post_id].to_s.strip
    platform = params[:platform].to_s.downcase.presence || 'facebook'

    if post_id.blank?
      return render json: { error: 'post_id is required' }, status: :bad_request
    end

    inbox = resolve_inbox
    return render json: { error: 'inbox not found' }, status: :not_found unless inbox

    access_token = resolve_access_token(inbox)
    unless access_token.present?
      return render json: { error: 'no access_token' }, status: :unprocessable_entity
    end

    if platform == 'instagram'
      fetch_instagram_post(post_id, access_token)
    else
      fetch_facebook_post(post_id, access_token)
    end
  end

  private

  def fetch_facebook_post(post_id, access_token)
    fields = 'message,full_picture,permalink_url,created_time'
    response = HTTParty.get(
      "#{FB_GRAPH_BASE}/#{post_id}",
      query: { fields: fields, access_token: access_token }
    )

    if response.success?
      data = response.parsed_response
      # Fallback permalink: construct from post_id if Graph API didn't return one
      permalink = data['permalink_url']
      if permalink.blank? && post_id.include?('_')
        page_id, story_id = post_id.split('_', 2)
        permalink = "https://www.facebook.com/#{page_id}/posts/#{story_id}"
      end
      render json: {
        post_id: post_id,
        platform: 'facebook',
        message: data['message'],
        picture: data['full_picture'],
        permalink: permalink,
        created_time: data['created_time']
      }, status: :ok
    else
      Rails.logger.warn("[OmniAi::PostInfo] FB Graph error for #{post_id}: #{response.code} #{response.body}")
      render json: { error: 'graph_api_error', code: response.code, details: response.parsed_response }, status: :unprocessable_entity
    end
  end

  def fetch_instagram_post(post_id, access_token)
    fields = 'caption,media_type,media_url,permalink,thumbnail_url,timestamp'
    response = HTTParty.get(
      "#{IG_GRAPH_BASE}/#{post_id}",
      query: { fields: fields, access_token: access_token }
    )

    if response.success?
      data = response.parsed_response
      picture = data['media_url'] || data['thumbnail_url']
      render json: {
        post_id: post_id,
        platform: 'instagram',
        message: data['caption'],
        picture: picture,
        permalink: data['permalink'],
        created_time: data['timestamp'],
        post_type: data['media_type']
      }, status: :ok
    else
      Rails.logger.warn("[OmniAi::PostInfo] IG Graph error for #{post_id}: #{response.code} #{response.body}")
      render json: { error: 'graph_api_error', code: response.code, details: response.parsed_response }, status: :unprocessable_entity
    end
  end

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
