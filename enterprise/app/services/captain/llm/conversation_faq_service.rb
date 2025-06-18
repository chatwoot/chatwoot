class Captain::Llm::ConversationFaqService < Llm::BaseOpenAiService
  DISTANCE_THRESHOLD = 0.3

  def initialize(assistant, conversation)
    super()
    @assistant = assistant
    @conversation = conversation
    @content = conversation.to_llm_text
  end

  # Generates and deduplicates FAQs from conversation content
  # Skips processing if there was no human interaction
  def generate_and_deduplicate
    return [] if no_human_interaction?

    new_faqs = generate
    return [] if new_faqs.empty?

    duplicate_faqs, unique_faqs = find_and_separate_duplicates(new_faqs)
    save_new_faqs(unique_faqs)
    log_duplicate_faqs(duplicate_faqs) if Rails.env.development?
  end

  private

  attr_reader :content, :conversation, :assistant

  def no_human_interaction?
    conversation.first_reply_created_at.nil?
  end

  def find_and_separate_duplicates(faqs)
    duplicate_faqs = []
    unique_faqs = []

    faqs.each do |faq|
      combined_text = "#{faq['question']}: #{faq['answer']}"
      embedding = Captain::Llm::EmbeddingService.new.get_embedding(combined_text)
      similar_faqs = find_similar_faqs(embedding)

      if similar_faqs.any?
        duplicate_faqs << { faq: faq, similar_faqs: similar_faqs }
      else
        unique_faqs << faq
      end
    end

    [duplicate_faqs, unique_faqs]
  end

  def find_similar_faqs(embedding)
    similar_faqs = assistant
                   .responses
                   .nearest_neighbors(:embedding, embedding, distance: 'cosine')
    Rails.logger.debug(similar_faqs.map { |faq| [faq.question, faq.neighbor_distance] })
    similar_faqs.select { |record| record.neighbor_distance < DISTANCE_THRESHOLD }
  end

  def save_new_faqs(faqs)
    faqs.map do |faq|
      assistant.responses.create!(
        question: faq['question'],
        answer: faq['answer'],
        status: 'pending',
        documentable: conversation
      )
    end
  end

  def log_duplicate_faqs(duplicate_faqs)
    return if duplicate_faqs.empty?

    Rails.logger.info "Found #{duplicate_faqs.length} duplicate FAQs:"
    duplicate_faqs.each do |duplicate|
      Rails.logger.info(
        "Q: #{duplicate[:faq]['question']}\n" \
        "A: #{duplicate[:faq]['answer']}\n\n" \
        "Similar existing FAQs: #{duplicate[:similar_faqs].map { |f| "Q: #{f.question} A: #{f.answer}" }.join(', ')}"
      )
    end
  end

  def generate
    response = @client.chat(parameters: chat_parameters)
    parse_response(response)
  rescue OpenAI::Error => e
    Rails.logger.error "OpenAI API Error: #{e.message}"
    []
  end

  def chat_parameters
    account_language = @conversation.account.locale_english_name
    prompt = Captain::Llm::SystemPromptsService.conversation_faq_generator(account_language)

    {
      model: @model,
      response_format: { type: 'json_object' },
      messages: [
        {
          role: 'system',
          content: prompt
        },
        {
          role: 'user',
          content: content
        }
      ]
    }
  end

  def parse_response(response)
    content = response.dig('choices', 0, 'message', 'content')
    return [] if content.nil?

    JSON.parse(content.strip).fetch('faqs', [])
  rescue JSON::ParserError => e
    Rails.logger.error "Error in parsing GPT processed response: #{e.message}"
    []
  end
end
