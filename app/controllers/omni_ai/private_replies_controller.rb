# frozen_string_literal: true

# POST /api/v1/omni_ai/private_reply
#
# Sends a Facebook/Instagram Private Reply to a commenter.
# Uses the Meta Private Replies API (POST /{page-id}/messages with recipient.comment_id)
# which allows sending 1 message to a commenter without a 24h messaging window.
#
# This also creates the contact, conversation and message records in Chatwoot
# so everything appears visually in the inbox.
#
# Auth: Authorization: Bearer {OMNI_AI_WEBHOOK_TOKEN}
# Body:
#   inbox_id    — Chatwoot Inbox ID (Facebook Page channel)
#   comment_id  — The Facebook/Instagram comment ID that triggered this
#   message_text — The DM text to send
#   platform    — "facebook" or "instagram"
#   commenter_name     — Display name (optional)
#   commenter_username — Username (optional)
#   commenter_id       — PSID / IGSID of the commenter (optional, for contact matching)
#   post_id            — Post ID (optional, stored in additional_attributes)
#   comment_lead_id    — Omni-AI comment lead UUID (optional, for linking)

class OmniAi::PrivateRepliesController < ActionController::API
  include OmniAi::InboxResolver

  FB_GRAPH_BASE = 'https://graph.facebook.com/v22.0'
  IG_GRAPH_BASE = 'https://graph.instagram.com/v22.0'

  before_action :verify_token

  def create
    comment_id   = params[:comment_id].to_s.strip
    message_text = params[:message_text].to_s.strip
    platform     = params[:platform].to_s.downcase.presence || 'facebook'

    if comment_id.blank? || message_text.blank?
      return render json: { error: 'comment_id and message_text are required' }, status: :bad_request
    end

    inbox = resolve_inbox
    return render json: { error: 'inbox not found' }, status: :not_found unless inbox

    access_token = resolve_access_token(inbox)
    return render json: { error: 'no access_token' }, status: :unprocessable_entity unless access_token.present?

    channel = inbox.channel
    page_id = channel.respond_to?(:page_id) ? channel.page_id : nil
    instagram_id = channel.respond_to?(:instagram_id) ? channel.instagram_id : nil

    # ── Step 1: Send Private Reply via Meta API ──
    # Instagram Private Replies use IG Graph API with the Instagram Business Account ID
    # Facebook Private Replies use FB Graph API with the Page ID
    if platform == 'instagram'
      graph_base = IG_GRAPH_BASE
      target_id = instagram_id || page_id
    else
      graph_base = FB_GRAPH_BASE
      target_id = page_id
    end

    unless target_id.present?
      return render json: { error: "no #{platform == 'instagram' ? 'instagram_id' : 'page_id'} for this channel" },
                    status: :unprocessable_entity
    end

    private_reply_response = HTTParty.post(
      "#{graph_base}/#{target_id}/messages",
      headers: { 'Content-Type' => 'application/json' },
      body: {
        recipient: { comment_id: comment_id },
        message: { text: message_text },
        access_token: access_token
      }.to_json
    )

    unless private_reply_response.success?
      error_body = private_reply_response.parsed_response
      Rails.logger.warn("[OmniAi::PrivateReply] Graph API error: #{private_reply_response.code} #{error_body}")
      return render json: {
        error: 'private_reply_failed',
        graph_error: error_body,
        code: private_reply_response.code
      }, status: :unprocessable_entity
    end

    fb_message_id = private_reply_response.parsed_response&.dig('message_id')
    fb_recipient_id = private_reply_response.parsed_response&.dig('recipient_id')
    Rails.logger.info("[OmniAi::PrivateReply] Sent: message_id=#{fb_message_id} recipient_id=#{fb_recipient_id}")

    # ── Step 2: Create/find contact + contact_inbox in Chatwoot ──
    commenter_id = fb_recipient_id || params[:commenter_id].to_s.strip.presence
    commenter_name = params[:commenter_name].to_s.strip.presence || params[:commenter_username].to_s.strip.presence || 'Facebook User'

    contact_inbox = find_or_build_contact_inbox(inbox, commenter_id, commenter_name)
    unless contact_inbox
      return render json: {
        success: true,
        private_reply_sent: true,
        fb_message_id: fb_message_id,
        conversation_created: false,
        note: 'Private reply sent but could not create Chatwoot contact/conversation'
      }, status: :ok
    end

    contact = contact_inbox.contact

    # ── Step 3: Find or create conversation ──
    conversation = find_or_create_conversation(inbox, contact, contact_inbox, platform)

    # ── Step 4: Create message record so it appears in Chatwoot ──
    message = conversation.messages.create!(
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      message_type: :outgoing,
      content: message_text,
      source_id: fb_message_id,
      sender: nil, # sent by automation, not a specific agent
      content_attributes: {
        private_reply: true,
        comment_id: comment_id,
        platform: platform
      }
    )

    # Store additional context on the conversation
    additional = conversation.additional_attributes || {}
    additional['source_platform'] = platform
    additional['comment_lead_id'] = params[:comment_lead_id] if params[:comment_lead_id].present?
    additional['commenter_username'] = params[:commenter_username] if params[:commenter_username].present?
    additional['post_id'] = params[:post_id] if params[:post_id].present?
    additional['comment_id'] = comment_id
    conversation.update_columns(additional_attributes: additional)

    render json: {
      success: true,
      private_reply_sent: true,
      fb_message_id: fb_message_id,
      fb_recipient_id: fb_recipient_id,
      conversation_id: conversation.display_id,
      conversation_uuid: conversation.uuid,
      contact_id: contact.id,
      message_id: message.id,
      conversation_created: true
    }, status: :ok

  rescue StandardError => e
    Rails.logger.error("[OmniAi::PrivateReply] Error: #{e.class} #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
    render json: { error: e.message }, status: :internal_server_error
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

  def find_or_build_contact_inbox(inbox, commenter_id, commenter_name)
    return nil if commenter_id.blank?

    # Try to find existing contact_inbox by source_id
    contact_inbox = inbox.contact_inboxes.find_by(source_id: commenter_id)
    return contact_inbox if contact_inbox

    # Build via Chatwoot's standard builder (handles dedup, contact creation, etc.)
    ::ContactInboxWithContactBuilder.new(
      inbox: inbox,
      source_id: commenter_id,
      contact_attributes: { name: commenter_name }
    ).perform
  rescue StandardError => e
    Rails.logger.warn("[OmniAi::PrivateReply] ContactInbox build failed: #{e.message}")
    nil
  end

  def find_or_create_conversation(inbox, contact, contact_inbox, platform)
    # Find existing open/pending conversation for this contact in this inbox
    existing = inbox.conversations
                    .where(contact: contact)
                    .where(status: [:open, :pending])
                    .order(updated_at: :desc)
                    .first
    return existing if existing

    # Create new conversation
    Conversation.create!(
      account: inbox.account,
      inbox: inbox,
      contact: contact,
      contact_inbox: contact_inbox,
      status: :open,
      additional_attributes: { source_platform: platform }
    )
  end
end
