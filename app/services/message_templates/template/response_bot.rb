class MessageTemplates::Template::ResponseBot
  pattr_initialize [:conversation!]

  def perform
    ActiveRecord::Base.transaction do
      response = get_response(conversation.messages.last.content)
      process_response(conversation.messages.last, response)
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
    true
  end

  private

  delegate :contact, :account, to: :conversation
  delegate :inbox, to: :message

  def get_response(content)
    previous_messages = []
    conversation.messages.where(message_type: [:outgoing, :incoming]).where(private: false).find_each do |message|
      next if message.content_type != 'text'

      role = message.message_type == 'incoming' ? 'user' : 'system'
      previous_messages << { content: message.content, role: role }
    end

    ChatGpt.new(response_sections(content)).generate_response('', previous_messages)
  end

  def response_sections(content)
    sections = ''

    Response.search(content).each do |response|
      break if response.neighbor_distance > 0.7

      sections += "{context_id: #{response.id}, context: #{response.question} ? #{response.answer}}"
    end
    sections
  end

  def process_response(message, response)
    if response == 'conversation_handoff'
      process_action(message, 'handoff')
    else
      create_messages(response, conversation)
    end
  end

  def create_messages(response, conversation)
    # Regular expression to match '{context_ids: [ids]}'
    regex = /{context_ids: \[(\d+(?:, *\d+)*)\]}/

    # Extract ids from string
    id_string = response[regex, 1] # This will give you '42, 43'
    article_ids = id_string.split(',').map(&:to_i) if id_string # This will give you [42, 43]

    # Remove '{context_ids: [ids]}' from string
    response = response.sub(regex, '')

    content_attributes = article_ids.present? ? get_article_hash(article_ids) : {}

    conversation.messages.create!(
      {
        message_type: :outgoing,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        content: response
      }
    )

    # create messages with cards
    return if content_attributes.blank?

    conversation.messages.create!(
      {
        message_type: :outgoing,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        content: 'suggested articles',
        content_type: 'article',
        content_attributes: content_attributes
      }
    )
  end

  def get_article_hash(article_ids)
    items = []
    article_ids.each do |article_id|
      response = Response.find(article_id)
      next if response.nil?

      items << { title: response.question, description: response.answer[0, 120], link: response.response_document.document_link }
    end

    items.present? ? { items: items } : {}
  end
end
