class Integrations::Notion::CreatePageService
  pattr_initialize [:hook!, :conversation!]

  def perform
    return unless notion_ready?

    page = client.create_page(parent_id, page_title, page_children, parent_type: parent_type)
    Rails.logger.info "Notion sync: created page #{page.dig(:id, :url)} for conversation #{conversation.display_id}" if page
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: hook.account).capture_exception
    Rails.logger.error "Notion sync failed for conversation #{conversation.display_id}: #{e.message}"
  end

  private

  def notion_ready?
    # If the parent page/database isn't configured yet, skip silently to keep resolution flow safe.
    return false if parent_id.blank? || conversation.blank?

    true
  end

  def client
    @client ||= Notion.new(hook.access_token)
  end

  def parent_id
    hook.settings&.dig('parent_page_id') || hook.settings&.dig('parent_database_id')
  end

  def parent_type
    parent_id == hook.settings&.dig('parent_database_id') ? :database_id : :page_id
  end

  def page_title
    "Conversation ##{conversation.display_id} — #{contact_name}"
  end

  def contact_name
    conversation.contact&.name.presence || conversation.contact&.email.presence || 'Unknown contact'
  end

  def page_children
    summary_blocks + transcript_blocks
  end

  def summary_blocks
    [heading_block('Conversation summary'), paragraph_block(conversation.to_llm_text(include_contact_details: true))]
  end

  def transcript_blocks
    messages = conversation.recent_messages
    return [] if messages.blank?

    blocks = [heading_block('Recent messages')]
    messages.each do |message|
      sender = message.sender.respond_to?(:name) ? message.sender.name : (message.incoming? ? 'Contact' : 'Agent')
      blocks << paragraph_block("#{sender}: #{message.content.to_s.force_encoding(Encoding::UTF_8)[0..3000]}")
    end
    blocks
  end

  def heading_block(content)
    { object: 'block', type: 'heading_2', heading_2: { rich_text: [{ type: 'text', text: { content: content[0..300] } }] } } }
  end

  def paragraph_block(content)
    { object: 'block', type: 'paragraph', paragraph: { rich_text: [{ type: 'text', text: { content: content[0..1900] } }] } } }
  end
end