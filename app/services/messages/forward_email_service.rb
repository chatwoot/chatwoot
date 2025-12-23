class Messages::ForwardEmailService # rubocop:disable Metrics/ClassLength
  pattr_initialize [:message!, :forward_to_emails!, :forward_comment, :user]

  def perform
    validate_message_type!
    validate_inbox_type!
    parsed_emails = parse_and_validate_emails

    # Create/find contacts for each recipient
    contacts = create_or_find_contacts(parsed_emails)

    # Create one conversation per recipient
    new_conversations = contacts.map do |contact|
      new_conversation = create_forwarded_conversation(contact)
      send_forwarded_message(new_conversation, contact.email)
      new_conversation
    end

    # Create activity in original conversation
    create_activity_message(new_conversations, parsed_emails)

    new_conversations
  rescue StandardError => e
    Rails.logger.error "Forward email failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  private

  def parse_and_validate_emails
    emails = forward_to_emails.split(',').map(&:strip).reject(&:blank?)

    emails.each do |email|
      raise ArgumentError, "Invalid email format: #{email}" unless valid_email?(email)
    end

    raise ArgumentError, 'At least one email address is required' if emails.empty?

    emails
  end

  def valid_email?(email)
    email.match?(URI::MailTo::EMAIL_REGEXP)
  end

  def validate_message_type!
    return if message.incoming? || message.outgoing?

    raise ArgumentError, 'Only incoming or outgoing messages can be forwarded'
  end

  def validate_inbox_type!
    return if conversation.inbox.inbox_type == 'Email'

    raise ArgumentError, 'Email forwarding is only available for email inboxes'
  end

  def create_or_find_contacts(emails)
    emails.map do |email|
      contact = conversation.account.contacts.from_email(email)

      if contact.nil?
        # Create new contact
        contact = conversation.account.contacts.create!(
          name: email.split('@').first,
          email: email
        )
        Rails.logger.info "Created new contact: #{contact.email} (ID: #{contact.id})"
      else
        Rails.logger.info "Found existing contact: #{contact.email} (ID: #{contact.id})"
      end

      # Ensure contact_inbox exists for this inbox
      ContactInboxBuilder.new(
        contact: contact,
        inbox: conversation.inbox,
        source_id: email
      ).perform

      contact
    end
  end

  def create_forwarded_conversation(contact)
    # Create new conversation for this contact
    new_conversation = conversation.account.conversations.create!(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      contact_id: contact.id,
      contact_inbox_id: contact.contact_inboxes.find_by(inbox_id: conversation.inbox_id)&.id,
      additional_attributes: {
        mail_subject: "Fwd: #{original_subject}",
        forwarded_from_conversation_id: conversation.id
      }
    )

    Rails.logger.info "Created new conversation: ##{new_conversation.display_id} (ID: #{new_conversation.id}) for #{contact.email}"
    new_conversation
  end

  def send_forwarded_message(new_conversation, recipient_email) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    # Build both plain text and HTML versions
    plain_text_content = build_forwarded_plain_content
    html_content = build_forwarded_html_content

    # Create message directly instead of using MessageBuilder to have full control over content_attributes
    # This ensures HTML content is set BEFORE any callbacks run
    forwarded_message = new_conversation.messages.create!(
      account_id: new_conversation.account_id,
      inbox_id: new_conversation.inbox_id,
      message_type: :outgoing,
      content: plain_text_content,
      private: false,
      sender: user,
      content_attributes: {
        to_emails: [recipient_email],
        email: {
          html_content: {
            full: html_content
          },
          text_content: {
            full: plain_text_content
          }
        }
      }
    )

    # Add attachments if any
    if message.attachments.present?
      message.attachments.each do |attachment|
        forwarded_message.attachments.create!(
          account_id: forwarded_message.account_id,
          file: attachment.file.blob,
          file_type: attachment.file_type
        )
      rescue StandardError => e
        Rails.logger.error "Failed to attach file: #{e.message}"
      end
    end

    Rails.logger.info 'Message created with HTML content'
    Rails.logger.info "HTML content present: #{forwarded_message.content_attributes.dig('email', 'html_content', 'full').present?}"
    Rails.logger.info "HTML content length: #{forwarded_message.content_attributes.dig('email', 'html_content', 'full')&.length || 0}"

    forwarded_message
  end

  def build_forwarded_plain_content # rubocop:disable Metrics/AbcSize
    content_parts = []

    # Add agent's comment if provided
    content_parts << forward_comment << "\n\n" if forward_comment.present?

    # Add forwarded message separator
    content_parts << "---------- Forwarded message ---------\n\n"

    # Add original message headers
    content_parts << "From: #{message.sender&.email || 'Unknown'}\n"
    content_parts << "Date: #{message.created_at.strftime('%a, %b %d, %Y at %I:%M %p')}\n"
    content_parts << "Subject: #{original_subject}\n"
    content_parts << "To: #{original_recipients.join(', ')}\n" if original_recipients.any?
    content_parts << "\n"

    # Add original message content
    content_parts << message.content

    content_parts.join
  end

  def build_forwarded_html_content # rubocop:disable Metrics/AbcSize
    html_parts = []

    # Add agent's comment if provided
    if forward_comment.present?
      html_parts << '<div style="margin-bottom: 20px; padding: 15px; background-color: #f7fafc; border-left: 4px solid #1f93ff; border-radius: 4px;">'
      html_parts << ERB::Util.html_escape(forward_comment).gsub("\n", '<br>')
      html_parts << '</div>'
    end

    # Add forwarded message separator
    html_parts << '<div style="margin: 30px 0 20px 0; padding: 10px 0; border-top: 2px solid #e2e8f0; font-weight: 600; color: #4a5568;">'
    html_parts << '---------- Forwarded message ---------'
    html_parts << '</div>'

    # Add original message headers
    html_parts << '<div style="margin: 15px 0; padding: 15px; background-color: #f9fafb; border-radius: 4px; font-size: 13px; line-height: 1.8;">'
    html_parts << "<strong>From:</strong> #{ERB::Util.html_escape(message.sender&.email || 'Unknown')}<br>"
    html_parts << "<strong>Date:</strong> #{message.created_at.strftime('%a, %b %d, %Y at %I:%M %p')}<br>"
    html_parts << "<strong>Subject:</strong> #{ERB::Util.html_escape(original_subject)}<br>"
    html_parts << "<strong>To:</strong> #{ERB::Util.html_escape(original_recipients.join(', '))}<br>" if original_recipients.any?
    html_parts << '</div>'

    # Add original message content
    html_parts << '<div style="margin-top: 20px; padding-top: 20px; border-top: 1px solid #e2e8f0;">'
    html_parts << message.content
    html_parts << '</div>'

    html_parts.join
  end

  def original_subject
    conversation.additional_attributes['mail_subject'] ||
      message.content_attributes.dig('email', 'subject') ||
      "Conversation ##{conversation.display_id}"
  end

  def original_recipients
    to_emails = message.content_attributes.dig('email', 'to') || []
    Array(to_emails)
  end

  def create_activity_message(new_conversations, emails) # rubocop:disable Metrics/MethodLength
    content = I18n.t(
      'conversations.activity.forwarded_email',
      agent: user&.available_name || 'Agent',
      emails: emails.join(', ')
    )

    # Add links to new conversations
    if new_conversations.size == 1
      content += " (Conversation ##{new_conversations.first.display_id})"
    else
      conversation_links = new_conversations.map { |c| "##{c.display_id}" }.join(', ')
      content += " (Conversations: #{conversation_links})"
    end

    conversation.messages.create!(
      message_type: :activity,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      content: content,
      content_attributes: {
        forwarded_to: emails,
        forwarded_message_id: message.id,
        forwarded_conversation_ids: new_conversations.map(&:id),
        forwarded_at: Time.current.iso8601
      }
    )
  end

  def conversation
    @conversation ||= message.conversation
  end
end
