class Enterprise::MessageTemplates::ResponseBotService
  pattr_initialize [:conversation!]

  def self.generate_sources_section(article_ids)
    sources_content = ''

    articles_hash = get_article_hash(article_ids.uniq)

    articles_hash.first(3).each do |article_hash|
      sources_content += " - [#{article_hash[:response].question}](#{article_hash[:response_document].document_link}) \n"
    end
    sources_content = "\n \n \n **Sources**  \n#{sources_content}" if sources_content.present?
    sources_content
  end

  def self.get_article_hash(article_ids)
    seen_documents = Set.new
    article_ids.uniq.filter_map do |article_id|
      response = Response.find(article_id)
      response_document = response.response_document
      next if response_document.blank? || seen_documents.include?(response_document)

      seen_documents << response_document
      { response: response, response_document: response_document }
    end
  end

  def self.response_sections(content, response_source)
    sections = ''

    response_source.get_responses(content).each do |response|
      sections += "{context_id: #{response.id}, context: #{response.question} ? #{response.answer}},"
    end
    sections
  end

  def perform
    ActiveRecord::Base.transaction do
      @response = get_response(conversation.messages.incoming.last.content)
      process_response
    end
  rescue StandardError => e
    process_action('handoff') # something went wrong, pass to agent
    ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
    true
  end

  private

  delegate :contact, :account, :inbox, to: :conversation

  def get_response(content)
    previous_messages = []
    get_previous_messages(previous_messages)
    ChatGpt.new(self.class.response_sections(content, inbox)).generate_response('', previous_messages)
  end

  def get_previous_messages(previous_messages)
    conversation.messages.where(message_type: [:outgoing, :incoming]).where(private: false).find_each do |message|
      next if message.content_type != 'text'

      role = determine_role(message)
      previous_messages << { content: message.content, role: role }
    end
  end

  def determine_role(message)
    message.message_type == 'incoming' ? 'user' : 'system'
  end

  def process_response
    if @response['response'] == 'conversation_handoff'
      process_action('handoff')
    else
      create_messages
    end
  end

  def process_action(action)
    case action
    when 'handoff'
      conversation.messages.create!('message_type': :outgoing, 'account_id': conversation.account_id, 'inbox_id': conversation.inbox_id,
                                    'content': 'Transferring to another agent for further assistance.')
      conversation.bot_handoff!
    end
  end

  def create_messages
    message_content = @response['response']
    message_content += self.class.generate_sources_section(@response['context_ids']) if @response['context_ids'].present?

    create_outgoing_message(message_content)
  end

  def create_outgoing_message(message_content)
    conversation.messages.create!(
      {
        message_type: :outgoing,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        content: message_content
      }
    )
  end
end
