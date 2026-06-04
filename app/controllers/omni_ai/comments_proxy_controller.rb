# frozen_string_literal: true

# Proxy controller that forwards Comments page requests from the Chatwoot
# frontend to the Omni-AI backend.  Keeps all comment data isolated in
# Omni-AI's own database — nothing stored in Chatwoot tables.
#
# Routes:
#   GET  /auth/omni_ai/comments/stats
#   GET  /auth/omni_ai/comments/by-post
#   GET  /auth/omni_ai/comments/post/:postId
#   GET  /auth/omni_ai/comments/post-info/:postId
#   PUT  /auth/omni_ai/comments/:id/reply
#   GET  /auth/omni_ai/comments/commenter/:commenterId
#   POST /auth/omni_ai/comments/:commentId/dm  — trigger DM via Chatwoot channel
#   GET  /auth/omni_ai/comments                — list all

class OmniAi::CommentsProxyController < Api::V1::Accounts::BaseController
  before_action :verify_access

  # Proxy GET requests to omni-ai backend
  def stats
    proxy_get('/api/internal/comments/stats')
  end

  def by_post
    proxy_get('/api/internal/comments/by-post', permitted_query(:platform, :q))
  end

  def post_comments
    proxy_get("/api/internal/comments/post/#{encoded_param(:post_id)}")
  end

  def post_info
    proxy_get("/api/internal/comments/post-info/#{encoded_param(:post_id)}", permitted_query(:platform))
  end

  def index
    proxy_get('/api/internal/comments', permitted_query(:platform, :status, :q, :limit))
  end

  def commenter_history
    proxy_get("/api/internal/comments/commenter/#{encoded_param(:commenter_id)}")
  end

  # Proxy PUT reply
  def reply
    proxy_put("/api/internal/comments/#{encoded_param(:id)}/reply", { reply: params[:reply] })
    broadcast_omni_comments_update
  end

  # DM flow: create/find contact, send message through Chatwoot channel
  def send_dm
    comment_id = params[:comment_id]
    dm_text = params[:dm_text]
    platform = params[:platform] || 'facebook'

    return render json: { error: 'dm_text required' }, status: :bad_request if dm_text.blank?

    # Fetch comment details from omni-ai to get commenter info
    comment_res = fetch_from_omni("/api/internal/comments/#{ERB::Util.url_encode(comment_id)}")
    return render json: { error: 'comment_not_found' }, status: :not_found unless comment_res

    fb_comment_id = comment_res['comment_id']
    commenter_id = comment_res['commenter_id']
    commenter_name = comment_res['commenter_name'] || comment_res['commenter_username'] || 'User'

    return render json: { error: 'no_facebook_comment_id' }, status: :unprocessable_entity if fb_comment_id.blank?

    # Use Private Reply API (7-day window) instead of standard Messenger DM (24h window)
    inbox_id = resolve_inbox_id(platform)
    return render json: { error: 'no_inbox_configured' }, status: :unprocessable_entity unless inbox_id

    inbox = Inbox.find_by(id: inbox_id)
    return render json: { error: 'inbox_not_found' }, status: :not_found unless inbox

    access_token = resolve_access_token(inbox)
    return render json: { error: 'no_access_token' }, status: :unprocessable_entity unless access_token.present?

    channel = inbox.channel
    page_id = channel.respond_to?(:page_id) ? channel.page_id : nil

    # Step 1: Send Private Reply via Meta Graph API
    graph_base = platform == 'instagram' ? 'https://graph.instagram.com/v22.0' : 'https://graph.facebook.com/v22.0'
    target_id = page_id || inbox_id

    private_reply_response = HTTParty.post(
      "#{graph_base}/#{target_id}/messages",
      headers: { 'Content-Type' => 'application/json' },
      body: {
        recipient: { comment_id: fb_comment_id },
        message: { text: dm_text },
        access_token: access_token
      }.to_json
    )

    unless private_reply_response.success?
      error_body = private_reply_response.parsed_response
      Rails.logger.warn("[OmniAi::CommentsProxy] Private Reply API error: #{private_reply_response.code} #{error_body}")
      return render json: {
        error: 'private_reply_failed',
        graph_error: error_body,
        code: private_reply_response.code
      }, status: :unprocessable_entity
    end

    fb_message_id = private_reply_response.parsed_response&.dig('message_id')
    fb_recipient_id = private_reply_response.parsed_response&.dig('recipient_id')
    Rails.logger.info("[OmniAi::CommentsProxy] Private Reply sent: message_id=#{fb_message_id} recipient_id=#{fb_recipient_id}")

    # Step 2: Create contact + conversation in Chatwoot so it appears in inbox
    resolved_commenter_id = fb_recipient_id || commenter_id
    contact_inbox = find_or_create_contact(inbox, resolved_commenter_id, commenter_name, platform)

    conversation = nil
    message = nil
    if contact_inbox
      conversation = find_or_create_conversation(contact_inbox, inbox)
      message = conversation.messages.create!(
        account: current_account,
        inbox: inbox,
        message_type: :outgoing,
        content: dm_text,
        source_id: fb_message_id,
        sender: current_user,
        content_attributes: {
          private_reply: true,
          comment_id: fb_comment_id,
          platform: platform
        }
      )
    end

    # Update omni-ai backend with DM info
    proxy_put("/api/internal/comments/#{ERB::Util.url_encode(comment_id)}/dm", {
      dm_text: dm_text,
      dm_conversation_id: conversation&.display_id&.to_s,
      dm_message_id: message&.id&.to_s,
      dm_contact_id: contact_inbox&.contact_id&.to_s
    })

    broadcast_omni_comments_update

    render json: {
      success: true,
      conversation_id: conversation&.display_id,
      message_id: message&.id,
      fb_message_id: fb_message_id
    }
  rescue StandardError => e
    Rails.logger.error("[OmniAi::CommentsProxy] DM send error: #{e.message}")
    render json: { error: 'dm_send_failed', details: e.message }, status: :unprocessable_entity
  end

  private

  def verify_access
    enabled = ENV.fetch('OMNI_COMMENTS_PAGE_ENABLED', 'false')
    return head :not_found unless enabled.to_s.downcase == 'true'

    allowed_ids = ENV.fetch('OMNI_COMMENTS_PAGE_USER_IDS', '')
    return if allowed_ids.strip.upcase == 'ALL'

    ids = allowed_ids.split(',').map(&:strip).map(&:to_i)
    head :forbidden unless ids.include?(current_user.id)
  end

  def broadcast_omni_comments_update(post_id: nil)
    ActionCable.server.broadcast(
      "account_#{current_account.id}",
      { event: 'omni_comments.updated', data: { post_id: post_id }.compact }
    )
  rescue StandardError => e
    Rails.logger.warn("[OmniAi::CommentsProxy] broadcast error: #{e.message}")
  end

  def omni_ai_base_url
    @omni_ai_base_url ||= ENV.fetch('OMNI_AI_WEBHOOK_URL', '').sub(%r{/webhooks/chatwoot\z}, '')
  end

  def omni_ai_token
    @omni_ai_token ||= ENV.fetch('OMNI_AI_COMMENTS_SECRET', ENV.fetch('OMNI_AI_WEBHOOK_TOKEN', ''))
  end

  def proxy_get(path, query_params = {})
    url = "#{omni_ai_base_url}#{path}"
    tok = omni_ai_token
    Rails.logger.info("[OmniAi::CommentsProxy] → GET #{url} | token_length=#{tok.length} first4=#{tok[0..3]}")
    response = HTTParty.get(url, query: query_params, headers: auth_headers, timeout: 15)
    Rails.logger.info("[OmniAi::CommentsProxy] ← #{response.code} #{response.body&.truncate(500)}")
    render json: response.parsed_response, status: response.code
  rescue StandardError => e
    Rails.logger.error("[OmniAi::CommentsProxy] GET #{path} error: #{e.message}")
    render json: { error: 'proxy_error', details: e.message }, status: :bad_gateway
  end

  def proxy_put(path, body = {})
    url = "#{omni_ai_base_url}#{path}"
    Rails.logger.info("[OmniAi::CommentsProxy] → PUT #{url}")
    response = HTTParty.put(url, body: body.to_json, headers: auth_headers.merge('Content-Type' => 'application/json'), timeout: 15)
    Rails.logger.info("[OmniAi::CommentsProxy] ← #{response.code} #{response.body&.truncate(500)}")
    render json: response.parsed_response, status: response.code
  rescue StandardError => e
    Rails.logger.error("[OmniAi::CommentsProxy] PUT #{path} error: #{e.message}")
    render json: { error: 'proxy_error', details: e.message }, status: :bad_gateway
  end

  def fetch_from_omni(path)
    url = "#{omni_ai_base_url}#{path}"
    response = HTTParty.get(url, headers: auth_headers, timeout: 10)
    response.success? ? response.parsed_response : nil
  rescue StandardError
    nil
  end

  def auth_headers
    { 'Authorization' => "Bearer #{omni_ai_token}" }
  end

  def encoded_param(key)
    ERB::Util.url_encode(params[key].to_s)
  end

  def permitted_query(*keys)
    params.permit(*keys).to_h.compact_blank
  end

  def resolve_inbox_id(platform)
    if platform == 'instagram'
      ENV['OMNI_AI_INSTAGRAM_INBOX_ID'].presence || current_account&.inboxes
        &.where(channel_type: 'Channel::Instagram')&.first&.id
    else
      ENV['OMNI_AI_FACEBOOK_INBOX_ID'].presence || current_account&.inboxes
        &.where(channel_type: 'Channel::FacebookPage')&.first&.id
    end
  end

  def find_or_create_contact(inbox, platform_id, name, platform)
    # Try finding existing contact_inbox by source_id
    contact_inbox = inbox.contact_inboxes.find_by(source_id: platform_id)
    return contact_inbox if contact_inbox

    # Create new contact
    contact = current_account.contacts.create!(
      name: name,
      identifier: platform_id
    )
    ContactInbox.create!(
      contact: contact,
      inbox: inbox,
      source_id: platform_id
    )
  rescue ActiveRecord::RecordInvalid => e
    # identifier uniqueness — find existing
    contact = current_account.contacts.find_by(identifier: platform_id)
    if contact
      ci = contact.contact_inboxes.find_by(inbox: inbox)
      return ci if ci
      ContactInbox.create!(contact: contact, inbox: inbox, source_id: platform_id)
    else
      Rails.logger.error("[OmniAi::CommentsProxy] Contact creation failed: #{e.message}")
      nil
    end
  end

  def find_or_create_conversation(contact_inbox, inbox)
    # Find recent open conversation
    conversation = current_account.conversations
      .where(inbox: inbox, contact_inbox: contact_inbox)
      .where(status: [:open, :pending])
      .order(created_at: :desc)
      .first

    return conversation if conversation

    # Create new conversation
    current_account.conversations.create!(
      inbox: inbox,
      contact: contact_inbox.contact,
      contact_inbox: contact_inbox,
      status: :open,
      assignee: current_user
    )
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
