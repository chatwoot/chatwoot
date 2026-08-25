class Integrations::Lark::SendOnLarkService
  pattr_initialize [:message!, :hook!]

  # This is a notification, not a transcript.
  CONTENT_LIMIT = 1000
  ANNOUNCED_KEY = 'lark_announced_at'.freeze

  # Inboxes such as the website widget keep replying into the same conversation after it is
  # resolved, so the marker is cleared on resolution and the next enquiry is announced again.
  def self.clear_announcement(conversation)
    return if conversation.additional_attributes[ANNOUNCED_KEY].blank?

    conversation.update!(additional_attributes: conversation.additional_attributes.except(ANNOUNCED_KEY))
  end

  def perform
    return unless message.incoming?
    return if announced?

    mark_announced if deliver
  end

  private

  delegate :conversation, to: :message
  delegate :contact, :inbox, to: :conversation

  def announced?
    conversation.additional_attributes[ANNOUNCED_KEY].present?
  end

  def mark_announced
    conversation.update!(additional_attributes: conversation.additional_attributes.merge(ANNOUNCED_KEY => Time.current.iso8601))
  end

  # Lark answers 200 with a non-zero code in the body when it rejects a message, so the body is
  # the only signal that the group actually received it.
  def deliver
    body = SafeFetch.fetch(
      hook.settings['webhook_url'],
      method: :post,
      body: payload.to_json,
      headers: { 'Content-Type' => 'application/json' },
      validate_content_type: false
    ) { |response| JSON.parse(response.tempfile.read) }

    return true if body['code'].to_i.zero?

    Rails.logger.error("Lark hook #{hook.id} rejected the message: #{body['code']} #{body['msg']}")
    false
  end

  def payload
    {
      msg_type: 'post',
      content: { post: { en_us: { title: title, content: post_content } } }
    }.merge(signature)
  end

  def post_content
    paragraphs = []
    paragraphs << [{ tag: 'text', text: description }] if description.present?
    paragraphs << [{ tag: 'a', text: I18n.t('integration_apps.lark.conversation_link'), href: link_to_conversation }]
    paragraphs
  end

  # Contacts from the website widget are often anonymous, so the name may be blank.
  def title
    [contact.name.presence, inbox.name].compact.join(' · ')
  end

  # For an email inbox processed_message_content is the reply with the quoted thread trimmed off.
  # message.content still holds the whole thread, so it is not a safe fallback there.
  def description
    return @description if defined?(@description)

    content = message.processed_message_content.presence
    content ||= message.content unless inbox.email?

    @description = content.presence && CGI.unescapeHTML(ActionView::Base.full_sanitizer.sanitize(content)).truncate(CONTENT_LIMIT)
  end

  # Custom bots reject the message unless timestamp and sign are present when the bot is
  # configured with signature verification. The signing key is "<timestamp>\n<secret>".
  def signature
    secret = hook.settings['secret'].presence
    return {} if secret.blank?

    timestamp = Time.current.to_i.to_s
    { timestamp: timestamp, sign: Base64.strict_encode64(OpenSSL::HMAC.digest('SHA256', "#{timestamp}\n#{secret}", '')) }
  end

  def link_to_conversation
    "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{conversation.account_id}/conversations/#{conversation.display_id}"
  end
end
