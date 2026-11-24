module Enterprise::Captain::ReplySuggestionService
  def make_api_call(messages:, model: nil, feature: nil, schema: nil, tools: [])
    return super if reply_tools.empty?

    super(messages: messages, model: model, feature: feature, schema: schema, tools: reply_tools)
  end

  private

  def use_search_tool?
    ChatwootApp.chatwoot_cloud? || ChatwootApp.self_hosted_paid?
  end

  def reply_tools
    @reply_tools ||= [
      (build_search_tool if offer_search_tool?),
      (build_canned_responses_tool if offer_canned_responses_tool?),
      (build_past_replies_tool if offer_past_replies_tool?)
    ].compact
  end

  # The search tool reads only approved FAQs, so without any it can only answer "No FAQs found".
  def offer_search_tool?
    return @offer_search_tool if defined?(@offer_search_tool)

    @offer_search_tool = use_search_tool? && searchable_faqs.approved.exists?
  end

  # With the tool, the prompt lists canned responses by name and the model reads only the ones it needs, so the trace
  # shows which it used, instead of every canned response being pasted into the prompt.
  def offer_canned_responses_tool?
    return @offer_canned_responses_tool if defined?(@offer_canned_responses_tool)

    @offer_canned_responses_tool = agent_reply_draft? && use_search_tool? && account.canned_responses.exists?
  end

  def saved_replies
    offer_canned_responses_tool? ? nil : super
  end

  def offer_past_replies_tool?
    agent_reply_draft? && past_replies_source.present?
  end

  # The OpenSearch index when the account's messages are in it. Self-hosted installations without it fall back to a
  # bounded Postgres search; Cloud does not, because a text match over Cloud's message table is too heavy.
  def past_replies_source
    return @past_replies_source if defined?(@past_replies_source)

    @past_replies_source = resolve_past_replies_source
  end

  def resolve_past_replies_source
    return skip_past_replies('the plan does not include Captain search') unless use_search_tool?
    return use_past_replies_source(:index) if messages_indexed?
    return skip_past_replies('messages are not indexed for this account') if ChatwootApp.chatwoot_cloud?

    use_past_replies_source(:database)
  end

  # Mirrors Message#should_index?: without these the account's messages are not in the search index.
  def messages_indexed?
    return false unless ChatwootApp.advanced_search_allowed? && account.feature_enabled?('advanced_search')

    !ChatwootApp.chatwoot_cloud? || account.feature_enabled?('advanced_search_indexing')
  end

  def skip_past_replies(reason)
    Rails.logger.info("[CAPTAIN][ReplySuggestion] Account #{account.id}: past reply search not offered, #{reason}")
    nil
  end

  def use_past_replies_source(source)
    Rails.logger.info("[CAPTAIN][ReplySuggestion] Account #{account.id}: past reply search uses #{source}")
    source
  end

  def prompt_variables
    variables = super
    variables = variables.merge('has_search_tool' => true) if offer_search_tool?
    if offer_canned_responses_tool?
      variables = variables.merge('has_canned_responses_tool' => true,
                                  'saved_reply_index' => Captain::Tools::GetCannedResponsesService.index_for(account))
    end
    variables = variables.merge('has_past_replies_tool' => true) if offer_past_replies_tool?
    variables
  end

  def build_search_tool
    Captain::Tools::SearchReplyDocumentationService.new(account: account, assistant: search_assistant)
  end

  def build_canned_responses_tool
    Captain::Tools::GetCannedResponsesService.new(account: account)
  end

  def build_past_replies_tool
    Captain::Tools::SearchPastRepliesService.new(account: account, user: user, conversation: conversation, source: past_replies_source)
  end

  # Same scope as Captain::Tools::SearchReplyDocumentationService#search_responses.
  def searchable_faqs
    search_assistant.present? ? search_assistant.responses : account.captain_assistant_responses
  end

  def search_assistant
    conversation&.inbox&.captain_assistant
  end
end
