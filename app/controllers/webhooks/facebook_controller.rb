require 'httparty'

class Webhooks::FacebookController < ActionController::API
  include MetaTokenVerifyConcern

  def valid_token?(token)
    token = ENV['FB_VERIFY_TOKEN']
  end

  def events
    Rails.logger.info('📩 [FB Webhook] Received events')
    challenge = params['hub.challenge']
    if challenge.present?
      render plain: challenge and return
    end

    begin
      handle_entries(params['entry'.freeze])
    rescue => e
      Rails.logger.error("❌ [FB Webhook] Unexpected error in events: #{e.message}")
    end

    head :ok
  end

  private

  def handle_entries(entries)
    entries.each do |entry|
      if entry['changes'.freeze]
        handle_changes(entry)
      elsif entry['messaging'.freeze]
        handle_messaging(entry)
      end
    end
  end

  def handle_changes(entry)
    page = Channel::FacebookPage.find_by(page_id: entry[:id])
    return unless page

    entry['changes'.freeze].each do |changes|
      Rails.logger.info("📌 [FB Webhook] Change detected: #{  changes.inspect}")

      next unless changes['value']['item'] == 'comment'
      next unless changes['value']['verb'] == 'add'

      comment_id = changes['value']['comment_id']
      cache_key = "fb_comment_#{comment_id}"

      if Rails.cache.exist?(cache_key)
        Rails.logger.info("⚠️ [FB Webhook] Duplicate event skipped for comment_id: #{comment_id}")
        next
      end
      Rails.cache.write(cache_key, true, expires_in: 2.seconds)

      contact_inbox = find_or_create_contact_inbox(changes, page)

      if contact_inbox.nil?
        Rails.logger.warn("⚠️ [FB Webhook] contact_inbox is nil, skipping further processing for comment_id: #{comment_id}")
        next
      end

      handle_conversation_and_message(changes, page, contact_inbox, entry[:id])
    end
  end

  def handle_messaging(entry)
    entry['messaging'.freeze].each do |messaging|
      Facebook::Messenger::Bot.receive(messaging)
    end
  end

  def find_or_create_contact_inbox(changes, page)
    from = changes.dig('value', 'from')
    from_id = from['id']
    from_name = from['name']

    if Channel::FacebookPage.exists?(page_id: from_id)
      Rails.logger.info("ℹ️ [FB Webhook] Ignoring comment from the page itself.")
      return nil
    end

    ContactInboxWithContactBuilder.new(
      inbox: page.inbox,
      contact_attributes: {
        name: from_name,
        identifier: from_id
      },
      source_id: from_id
    ).perform
  rescue => e
    Rails.logger.error("❌ [FB Webhook] Error in find_or_create_contact_inbox: #{e.message}")
    nil
  end

  def handle_conversation_and_message(changes, page, contact_inbox, page_id)
    return if contact_inbox.nil?

    conversation = find_or_create_conversation(changes, page, contact_inbox)
    return if conversation.nil?

    create_message(changes, page, contact_inbox, conversation, page_id)
  end

  def find_or_create_conversation(changes, page, contact_inbox)
    return nil if contact_inbox.nil?

    parent_id = changes['value']['parent_id']
    comment_id = changes['value']['comment_id']
    platform_type = changes['value']['platform'] == 'instagram' ? 'instagram_comments' : 'feed_comments'

    conversation = Conversation.where("additional_attributes->>'comment_id' = ?", parent_id || comment_id).last
    return conversation if conversation.present?

    contact = contact_inbox.contact
    return nil if contact.nil?

    conversation = Conversation.create!(
      account_id: page.account_id,
      inbox_id: page.inbox.id,
      status: 'open',
      contact_id: contact.id,
      contact_inbox_id: contact_inbox.id,
      additional_attributes: {
        type: platform_type,
        comment_id: parent_id || comment_id
      }
    )

    Rails.logger.info("✅ [FB Webhook] Conversation created successfully for comment_id: #{comment_id}")

    conversation.update!(
      additional_attributes: conversation.additional_attributes.merge('comment_id' => comment_id)
    )

    conversation
  rescue => e
    Rails.logger.error("❌ [FB Webhook] Error creating conversation: #{e.message}")
    nil
  end

  def create_message(changes, page, contact_inbox, conversation, page_id)
    comment_id = changes['value']['comment_id']

    return if Message.exists?(source_id: comment_id)

    Message.create!(
      content: changes['value']['message'],
      account: page.account,
      inbox: page.inbox,
      conversation: conversation,
      sender: contact_inbox.contact,
      message_type: :incoming,
      source_id: comment_id
    )

    Rails.logger.info("✅ [FB Webhook] Message created successfully for comment_id: #{comment_id}")


    SendCommentReplyJob.set(wait: 10.seconds).perform_later(contact_inbox.id, conversation)
    SendTemplateDmJob.set(wait: 20.seconds).perform_later(contact_inbox.id, conversation,comment_id)
  rescue => e
    Rails.logger.error("❌ [FB Webhook] Error creating message: #{e.message}")
  end

  def enqueue_comment_reply_job(contact_inbox_id, conversation)
    job_cache_key = "fb_reply_job_#{conversation.id}"
    return if Rails.cache.exist?(job_cache_key)

    Rails.cache.write(job_cache_key, true, expires_in: 30.seconds)
    Rails.logger.info("🚀 [FB Webhook] Reply job enqueued for conversation: #{conversation.id}")
  end
end
