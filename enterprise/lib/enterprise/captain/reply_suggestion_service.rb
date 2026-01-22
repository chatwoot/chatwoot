module Enterprise::Captain::ReplySuggestionService
  def make_api_call(model:, messages:)
    make_api_call_with_tools(
      model: model,
      messages: messages,
      tools: [build_search_tool]
    )
  end

  private

  def prompt_variables
    super.merge('has_search_tool' => true)
  end

  def build_search_tool
    assistant = conversation&.inbox&.captain_assistant
    Captain::Tools::SearchReplyDocumentationService.new(account: account, assistant: assistant)
  end
end
