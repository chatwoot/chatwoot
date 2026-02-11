class Captain::Tools::SearchReplyDocumentationService < RubyLLM::Tool
  prepend Captain::Tools::Instrumentation

  description 'Search and retrieve documentation/FAQs from knowledge base'

  param :query, desc: 'Search Query', required: true

  def initialize(account:, assistant: nil)
    @account = account
    @assistant = assistant
    super()
  end

  def name
    'search_documentation'
  end

  def execute(query:)
    Rails.logger.info { "#{self.class.name}: #{query}" }

    translated_query = Captain::Llm::TranslateQueryService
                       .new(account: @account)
                       .translate(query, target_language: @account.locale_english_name)

    responses = search_responses(translated_query)
    return 'No FAQs found for the given query' if responses.empty?

    responses.map { |response| format_response(response) }.join
  end

  private

  def search_responses(query)
    if @assistant.present?
      @assistant.responses.approved.search(query, account_id: @account.id)
    else
      @account.captain_assistant_responses.approved.search(query, account_id: @account.id)
    end
  end

  def format_response(response)
    result = "\nQuestion: #{response.question}\nAnswer: #{response.answer}\n"
    result += "Source: #{response.documentable.external_link}\n" if response.documentable.present? && response.documentable.try(:external_link)
    result
  end
end
