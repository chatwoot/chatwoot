class SendCommentReplyJob < ApplicationJob
  queue_as :default

  def perform(contact_inbox_id, conversation)
    Rails.logger.info "=================== SendCommentReplyJob START ==================="


    contact_inbox = ContactInbox.find_by(id: contact_inbox_id)
    unless contact_inbox
      Rails.logger.error "❌ ContactInbox not found for ID: #{contact_inbox_id}"
      return
    end

    account = contact_inbox.inbox.account
    unless account
      Rails.logger.error "❌ Account not found for ContactInbox ID: #{contact_inbox_id}"
      return
    end

    return if conversation.nil?

    comment_id = conversation&.additional_attributes&.[]('comment_id')
    if comment_id.blank?
      Rails.logger.error "❌ Missing comment_id for conversation: #{conversation.id}"
      return
    end

    message_content = "Thanks for dropping us a comment 💬. We replied via DM, take a look when you have a sec."

    job_key = "comment_reply_job_#{conversation.id}"
    if Rails.cache.exist?(job_key)
      Rails.logger.info "⏩ Duplicate job skipped for conversation #{conversation.id}"
      return
    end
    Rails.cache.write(job_key, true, expires_in: 5.seconds)

    if conversation.messages.exists?(message_type: :outgoing, content: message_content)
      Rails.logger.info "⏩ Skipping duplicate reply for conversation #{conversation.id}"
      return
    end

    # Check type of comment (Instagram or Facebook)
    case conversation.additional_attributes['type']
    when 'instagram_comments'
      send_to_instagram_page(contact_inbox, conversation, message_content)
    when 'facebook_comments', 'feed_comments'  # <--- Add 'feed_comments' here
      send_to_facebook_page(contact_inbox, conversation, message_content)
    else
      Rails.logger.warn "⚠️ Unsupported comment type: #{conversation.additional_attributes['type']}"
    end    

  end

  private

  def send_to_facebook_page(contact_inbox, conversation, message_content)

    channel = contact_inbox.inbox.channel
    access_token = channel.page_access_token
    app_secret_proof = calculate_app_secret_proof(GlobalConfigService.load('FB_APP_SECRET', ''), access_token)

    query = { access_token: access_token }
    query[:appsecret_proof] = app_secret_proof if app_secret_proof

    comment_id = conversation.additional_attributes['comment_id']
    url = build_facebook_url(comment_id)

    Rails.logger.info "🌐 Sending Facebook reply → URL: #{url}"

    response = post_to_facebook(url, message_content, query)
    Rails.logger.info "📩 Facebook API response: #{response.inspect}"

    if response['error'].present?
      Rails.logger.error "❌ Facebook API error: #{response['error']}"
      return
    end

    conversation.messages.create!(
      content: message_content,
      account: contact_inbox.inbox.account,
      inbox: contact_inbox.inbox,
      sender: conversation.assignee || contact_inbox.inbox.account.users.first,
      message_type: :outgoing,
      source_id: response['id'] || response['message_id'],
      private: false
    )

    Rails.logger.info "✅ Facebook reply sent successfully for comment_id #{comment_id}"
  end

  def build_facebook_url(comment_id)
    "https://graph.facebook.com/v23.0/#{comment_id}/comments"
  end

  def post_to_facebook(url, message_text, query)
    HTTParty.post(
      url,
      headers: { 'Content-Type' => 'application/json' },
      query: query,
      body: { message: message_text }.to_json
    )
  end

  def calculate_app_secret_proof(app_secret, access_token)
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), app_secret, access_token)
  end

  # New method for Instagram reply
  def send_to_instagram_page(contact_inbox, conversation, message_content)

    channel = contact_inbox.inbox.channel
    access_token = channel.access_token

    comment_id = conversation.additional_attributes['comment_id']
    unless comment_id
      Rails.logger.error "❌ Missing comment_id for Instagram comment"
      return
    end

    url = "https://graph.instagram.com/v23.0/#{comment_id}/replies"

    response = HTTParty.post(
      url,
      body: {
        message: message_content,
        access_token: access_token
      }
    )

    Rails.logger.info "📩 Instagram API response: #{response.inspect}"

    if response.code != 200 || response['error'].present?
      Rails.logger.error "❌ Instagram API error: #{response['error'] || response.body}"
      return
    end

    conversation.messages.create!(
      content: message_content,
      account: contact_inbox.inbox.account,
      inbox: contact_inbox.inbox,
      sender: conversation.assignee || contact_inbox.inbox.account.users.first,
      message_type: :outgoing,
      source_id: response['id'] || response['message_id'],
      private: false
    )

    Rails.logger.info "✅ Instagram reply sent successfully for comment_id #{comment_id}"
  end
end

