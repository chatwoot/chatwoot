class Integrations::Gpt::ProcessorService < Integrations::BotProcessorService
  pattr_initialize [:event_name!, :event_data!, :agent_bot!]

  private

  def get_response(_source_id, content)
    previous_messages = []
    conversation.messages.where(message_type: [:outgoing, :incoming]).where(private: false).each do |message|
      next if message.content_type != 'text'

      role = message.message_type == 'incoming' ? 'user' : 'system'
      previous_messages << { content: message.content, role: role }
    end

    ChatGpt.new(agent_bot.bot_config['api_key'], context_sections(content)).generate_response('', previous_messages)
  end

  def context_sections(content)
    sections = ''
    hook = agent_bot.account.hooks.find { |app| app.app_id == 'openai' }
    Integrations::Openai::EmbeddingsService.new(hook: hook).search_article_embeddings(content).each do |article|
      break if article.neighbor_distance > 0.7

      sections += "{context_id: #{article.obj.id}, context: #{article.obj.title} ? #{article.obj.content}}"
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
        content: response,
        sender: agent_bot
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
        content_attributes: content_attributes,
        sender: agent_bot
      }
    )
  end

  def get_article_hash(article_ids)
    items = []
    article_ids.each do |article_id|
      article = agent_bot.account.articles.find(article_id)
      next if article.nil?

      items << { title: article.title, description: article.content[0, 120], link: article.article_link }
    end

    items.present? ? { items: items } : {}
  end
end
