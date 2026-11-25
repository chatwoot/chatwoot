module Enterprise::Captain::ReplySuggestionService
  def make_api_call(messages:, model: nil, feature: nil, schema: nil, tools: [])
    return super unless offer_search_tool?

    super(messages: messages, model: model, feature: feature, schema: schema, tools: [build_search_tool])
  end

  private

  def use_search_tool?
    ChatwootApp.chatwoot_cloud? || ChatwootApp.self_hosted_paid?
  end

  # The search tool reads only approved FAQs, so without any it can only answer "No FAQs found".
  def offer_search_tool?
    return @offer_search_tool if defined?(@offer_search_tool)

    @offer_search_tool = use_search_tool? && Captain::AssistantResponse.for_reply_search(account: account, assistant: search_assistant).exists?
  end

  def prompt_variables
    return super unless offer_search_tool?

    super.merge('has_search_tool' => true)
  end

  def build_search_tool
    Captain::Tools::SearchReplyDocumentationService.new(account: account, assistant: search_assistant)
  end

  def search_assistant
    conversation&.inbox&.captain_assistant
  end
end
