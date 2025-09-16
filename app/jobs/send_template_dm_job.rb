class SendTemplateDmJob < ApplicationJob
  queue_as :default

  def perform(contact_inbox_id, conversation, comment_id)
    Rails.logger.info "=================== SendTemplateDmJob START =======comment_id #{comment_id}============"

    contact_inbox = ContactInbox.find_by(id: contact_inbox_id)
    unless contact_inbox
      Rails.logger.error "❌ ContactInbox not found for ID: #{contact_inbox_id}"
      return
    end

    if conversation.nil?
      Rails.logger.error "❌ Conversation is nil"
      return
    end

    account = contact_inbox.inbox.account
    unless account
      Rails.logger.error "❌ Account not found for ContactInbox ID: #{contact_inbox_id}"
      return
    end

    contact = conversation.contact
    inbox = contact_inbox.inbox
    recipient_id = contact.get_source_id(inbox.id) if contact && inbox

    Rails.logger.info "=================== recipient_id ================== #{recipient_id} =================="
    if recipient_id.blank?
      Rails.logger.error "❌ Missing recipient_id for conversation: #{conversation.id}"
      return
    end

    template_message = "Hi! 👋 Thanks for engaging! Let me know if you need any specific information or have any questions!"

    job_key = "template_dm_job_#{contact_inbox.id}_#{contact.id}_#{comment_id}"
    puts "================job_key==================#{job_key}==================="
    
    if Rails.cache.exist?(job_key)
      Rails.logger.info "⏩ Duplicate template DM job skipped for contact_inbox #{contact_inbox.id}, contact #{contact.id}, comment #{comment_id}"
      return
    end
    
    Rails.cache.write(job_key, true, expires_in: 5.minutes)

    case conversation.additional_attributes['type']
    when 'instagram_comments', 'instagram_dm'
      send_instagram_dm(contact_inbox, recipient_id, template_message, comment_id)
    when 'facebook_comments', 'facebook_dm', 'feed_comments'
      send_facebook_dm(contact_inbox, recipient_id, template_message, comment_id)
    else
      Rails.logger.warn "⚠️ Unsupported type for template DM: #{conversation.additional_attributes['type']}"
    end

    Rails.logger.info "=================== SendTemplateDmJob END ==================="
  end

  private

  def find_or_create_template_dm_conversation(contact_inbox, contact, inbox, account)
    template_dm_conversation = Conversation.joins(contact_inbox: { contact: :account }, inbox: :account)
      .where(
        "conversations.contact_id = ? AND conversations.inbox_id = ? AND inboxes.account_id = ? AND conversations.additional_attributes->>'type' = ?",
        contact.id,
        inbox.id,
        account.id,
        'template_dm'
      )
      .last

    if template_dm_conversation.nil?
      Rails.logger.info "No existing conversation found, creating a new one for contact #{contact.id} in inbox #{inbox.id}"
      template_dm_conversation = Conversation.create!(
        contact: contact,
        inbox: inbox,
        account: account,
        contact_inbox: contact_inbox,
        additional_attributes: { 'type' => 'template_dm' }
      )
    else
      Rails.logger.info "Found existing conversation #{template_dm_conversation.id} for contact #{contact.id} in inbox #{inbox.id}"
    end

    template_dm_conversation
  end

  def send_facebook_dm(contact_inbox, recipient_id, template_message, comment_id)
    channel = contact_inbox.inbox.channel
    access_token = channel.page_access_token
    page_id = channel.page_id
    app_secret = ENV.fetch('FB_APP_SECRET', '')
    app_secret_proof = calculate_app_secret_proof(app_secret, access_token)

    query = { access_token: access_token }
    query[:appsecret_proof] = app_secret_proof if app_secret_proof.present?

    url = "https://graph.facebook.com/v23.0/#{page_id}/messages"

    body = {
      messaging_type: 'RESPONSE',
      recipient: { comment_id: comment_id },
      message: { text: template_message }
    }

    contact = contact_inbox.contact
    inbox = contact_inbox.inbox
    account = inbox.account

    template_dm_conversation = find_or_create_template_dm_conversation(contact_inbox, contact, inbox, account)

    if template_dm_conversation.messages.exists?(message_type: :outgoing, content: template_message)
      Rails.logger.info "⏩ Skipping duplicate template DM in conversation #{template_dm_conversation.id}"
      return
    end

    response = HTTParty.post(
      url,
      headers: { 'Content-Type' => 'application/json' },
      query: query,
      body: body.to_json
    )

    if response.code != 200 || response['error'].present?
      Rails.logger.error "❌ Facebook DM Template API error: #{response['error'] || response.body}"
      return
    end

    template_dm_conversation.messages.create!(
      content: template_message,
      account: account,
      inbox: inbox,
      sender: template_dm_conversation.assignee || account.users.first,
      message_type: :outgoing,
      source_id: response['message_id'] || nil,
      private: false
    )

    Rails.logger.info "✅ Facebook Template DM sent successfully"
  end

  def send_instagram_dm(contact_inbox, recipient_id, template_message, comment_id)
    channel = contact_inbox.inbox.channel
    access_token = channel.page_access_token
    page_id = channel.page_id

    url = "https://graph.facebook.com/v23.0/#{page_id}/messages"

    body = {
      recipient: { comment_id: comment_id },
      message: { text: template_message }
    }

    contact = contact_inbox.contact
    inbox = contact_inbox.inbox
    account = inbox.account

    template_dm_conversation = find_or_create_template_dm_conversation(contact_inbox, contact, inbox, account)

    if template_dm_conversation.messages.exists?(message_type: :outgoing, content: template_message)
      Rails.logger.info "⏩ Skipping duplicate template DM in conversation #{template_dm_conversation.id}"
      return
    end

    response = HTTParty.post(
      url,
      headers: { 'Content-Type' => 'application/json' },
      query: { access_token: access_token },
      body: body.to_json
    )

    if response.code != 200 || response['error'].present?
      Rails.logger.error "❌ Instagram DM Template API error: #{response['error'] || response.body}"
      return
    end

    template_dm_conversation.messages.create!(
      content: template_message,
      account: account,
      inbox: inbox,
      sender: template_dm_conversation.assignee || account.users.first,
      message_type: :outgoing,
      source_id: response['message_id'] || nil,
      private: false
    )

    Rails.logger.info "✅ Instagram Template DM sent successfully"
  end

  def calculate_app_secret_proof(app_secret, access_token)
    return nil if app_secret.blank? || access_token.blank?
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), app_secret, access_token)
  end
end
