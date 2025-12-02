class Webhooks::InstagramController < ActionController::API
  include MetaTokenVerifyConcern

  def events
    Rails.logger.info('📩 [IG Webhook] Received events')

    # Webhook verification
    challenge = params['hub.challenge']
    render plain: challenge and return if challenge.present?

    handle_entries(params['entry'])
    head :no_content
  end

  private

  def handle_entries(entries)
    entries.each do |entry|
      if entry['changes']
        handle_changes(entry)
      elsif entry['messaging']
        handle_messaging(entry)
      end
    end
  end

  def handle_changes(entry)
    page = Channel::Instagram.find_by(instagram_id: entry[:id])
    return unless page

    entry['changes'].each do |changes|
      Rails.logger.info("📌 [IG Webhook] Change detected: #{changes.inspect}")
      next unless changes['field'] == 'comments'

      comment_id = changes['value']['id']
      Rails.logger.info("📌 Processing comment_id: #{comment_id}")
      next unless comment_id.present?

      # Idempotent cache write (atomic)
      cache_key = "ig_comment_#{comment_id}"
      was_written = Rails.cache.fetch(cache_key, expires_in: 10.seconds, unless_exist: true) { true }
      unless was_written
        Rails.logger.info("⚠️ [IG Webhook] Duplicate event skipped for comment_id: #{comment_id}")
        next
      end

      contact_inbox = find_or_create_contact_inbox(changes, page)
      next unless contact_inbox

      conversation = find_or_create_conversation(changes, page, contact_inbox)
      create_message(changes, page, contact_inbox, conversation)
    end
  end

  def handle_messaging(entry)
    page = Channel::Instagram.find_by(instagram_id: entry['id'])

    if page.nil?
      Rails.logger.warn("⚠️ No FacebookPage found for instagram_id #{entry['id']}")
      return
    end
  
    entry['messaging'].each do |messaging|
      Rails.logger.info("📥 Processing messaging payload: #{messaging}")
      Webhooks::InstagramEventsJob.perform_later(messaging.to_json)
    end
  end
  

  def find_or_create_contact_inbox(changes, page)
    from = changes.dig('value', 'from')
    from_id = from['id']
    from_name = from['username'] || from['name']

    return nil if from_id.to_s == page.instagram_id.to_s

    contact_inbox = ContactInbox.find_by(source_id: from_id, inbox_id: page.inbox.id)
    return contact_inbox if contact_inbox.present?

    contact = Contact.find_by("additional_attributes->>'instagram_id' = ?", from_id.to_s)
    unless contact
      contact = Contact.create!(
        name: from_name,
        account_id: page.account_id,
        last_activity_at: Time.now.utc,
        additional_attributes: { instagram_id: from_id }
      )
    end

    ContactInbox.create!(
      contact: contact,
      inbox: page.inbox,
      source_id: from_id
    )
  end

  def find_or_create_conversation(changes, page, contact_inbox)
    comment_id = changes['value']['id']
    parent_id = changes['value']['parent_id']
  
  
    Rails.logger.info("🔎 [IG] comment_id=#{comment_id}")
  
    # Try to find an existing conversation with the same comment_id or media_id
    conversation = Conversation.where("additional_attributes->>'comment_id' = ?", parent_id).last

    # If an existing conversation is found, return it
    if conversation.present?
      return conversation
    else
      # No conversation found, proceed to create a new conversation
  
      new_conversation = Conversation.create!(
        account_id: page.account_id,
        inbox_id: page.inbox.id,
        status: 'open',
        contact_id: contact_inbox.contact.id,
        contact_inbox_id: contact_inbox.id,
        additional_attributes: {
          type: 'instagram_comments',
          comment_id: comment_id,
          media_id: changes['value']['media_id']
        }
      ).tap do |conv|
  
        Rails.logger.info("✅ [IG Webhook] Conversation created successfully for comment_id: #{comment_id}")
      end
  
      return new_conversation
    end
  end


  def create_message(changes, page, contact_inbox, conversation)
    comment_id = changes['value']['id']

    Rails.logger.info("📌 [IG Webhook] Creating message for comment_id: #{comment_id}")

    # return if Message.exists?(source_id: comment_id)

    msg = Message.where(source_id: comment_id).last

    return if msg.present?

    Message.create!(
      content: changes['value']['text'],
      account: page&.account,
      inbox: page&.inbox,
      conversation: conversation,
      sender: contact_inbox.contact,
      message_type: :incoming,
      source_id: comment_id
    )

    # Job deduplication (best-effort)
    unless job_already_enqueued?(contact_inbox.id, conversation.id, comment_id)
      SendCommentReplyJob.set(wait: 5.seconds).perform_later(contact_inbox.id, conversation)
      SendTemplateDmJob.set(wait: 10.seconds).perform_later(contact_inbox.id, conversation, comment_id)
    end
  end

  def job_already_enqueued?(contact_inbox_id, conversation_id, comment_id)
    cache_key = "job_#{contact_inbox_id}_#{conversation_id}_#{comment_id}"
    return true if Rails.cache.read(cache_key).present?

    Rails.cache.write(cache_key, true, expires_in: 30.seconds)
    false
  end

  def valid_token?(token)
    # Validates against both IG_VERIFY_TOKEN (Instagram channel via Facebook page) and
    # INSTAGRAM_VERIFY_TOKEN (Instagram channel via direct Instagram login)
    token == GlobalConfigService.load('IG_VERIFY_TOKEN', '') ||
      token == GlobalConfigService.load('INSTAGRAM_VERIFY_TOKEN', '')
  end
end
