# Finds actions in a scenario instruction that an available tool performs but the instruction does not reference, so the
# scenario editor can link them before saving. Without the link the scenario agent never gets the tool.
class Captain::ScenarioToolSuggestionService < Captain::BaseTaskService
  include Concerns::CaptainToolsHelpers

  RESPONSE_SCHEMA = Captain::ScenarioToolSuggestionSchema

  pattr_initialize [:assistant!, :instruction!]

  def perform
    response = make_api_call(feature: 'scenario_tool_suggestion', messages: messages, schema: RESPONSE_SCHEMA)
    return response if response[:error]

    { suggestions: valid_suggestions(response[:message]) }
  end

  private

  def account
    assistant.account
  end

  def messages
    [
      { role: 'system', content: Captain::PromptRenderer.render('scenario_tool_suggestion') },
      { role: 'user', content: JSON.pretty_generate(instructions: instruction, available_tools: available_tools) }
    ]
  end

  def available_tools
    @available_tools ||= assistant.available_agent_tools.map { |tool| tool.slice(:id, :title, :description) }
  end

  # The model may return a tool that does not exist, one the instruction already links, or a phrase it rewrote.
  # The editor replaces the phrase verbatim, so only phrases found outside existing tool links are kept.
  def valid_suggestions(message)
    suggestions = Array(message&.dig('suggestions')).filter_map do |suggestion|
      tool = available_tools.find { |available_tool| available_tool[:id] == suggestion['tool_id'] }
      phrase = suggestion['phrase'].to_s.strip
      next unless linkable?(tool, phrase)

      { tool_id: tool[:id], tool_title: tool[:title], phrase: phrase, replacement: "#{phrase} using [@#{tool[:title]}](tool://#{tool[:id]})" }
    end

    suggestions.uniq { |suggestion| suggestion[:tool_id] }
  end

  def linkable?(tool, phrase)
    return false if tool.nil? || phrase.blank?
    return false if extract_tool_ids_from_text(instruction).include?(tool[:id])

    instruction.gsub(TOOL_REFERENCE_REGEX, '').include?(phrase)
  end

  def event_name
    'captain_scenario_tool_suggestion'
  end

  def captain_tasks_enabled?
    account.feature_enabled?('captain_integration')
  end

  def counts_toward_usage?
    false
  end

  def build_follow_up_context?
    false
  end
end
