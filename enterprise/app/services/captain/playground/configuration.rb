require 'digest'

class Captain::Playground::Configuration
  MAX_KNOWLEDGE_LENGTH = 10_000

  class Invalid < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
      super('Invalid playground configuration')
    end
  end

  def self.reject_v1!
    raise Invalid, { 'playground_config' => ['is only available with Captain V2'] }
  end

  attr_reader :assistant, :knowledge_text, :response_guidelines, :guardrails

  def initialize(assistant:, params:)
    @assistant = assistant
    @errors = {}
    @params = normalize_params(params)
    @temporary_metadata = {}.compare_by_identity
    @scenario_agent_names = {}.compare_by_identity

    resolve_scenarios
    resolve_rules
    resolve_knowledge
    raise Invalid, @errors if @errors.any?
  end

  def scenarios
    @selected_scenarios + @temporary_scenarios
  end

  def temporary?(scenario)
    @temporary_metadata.key?(scenario)
  end

  def agent_name_for(scenario)
    @scenario_agent_names.fetch(scenario)
  end

  def prompt_context_for(agentable, context)
    overrides = {
      response_guidelines: response_guidelines,
      guardrails: guardrails,
      playground_knowledge: knowledge_text.presence
    }
    overrides[:scenarios] = scenario_prompt_context if agentable == assistant
    context.merge(overrides)
  end

  def handler_for(agent_name)
    scenario = scenarios.find { |candidate| agent_name_for(candidate) == agent_name }
    return assistant_handler unless scenario

    {
      type: 'scenario',
      id: scenario.id,
      title: scenario.title,
      temporary: temporary?(scenario)
    }
  end

  private

  def normalize_params(params)
    value = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params
    raise Invalid, { 'playground_config' => ['must be an object'] } unless value.is_a?(Hash)

    value.with_indifferent_access
  end

  def resolve_scenarios
    @selected_scenarios = selected_scenarios
    @temporary_scenarios = temporary_scenario_params.map.with_index do |attributes, index|
      build_temporary_scenario(attributes, index)
    end
    validate_temporary_client_ids
    @scenario_agent_names = build_scenario_agent_names
  end

  def selected_scenarios
    ids = selected_scenario_ids
    unless valid_scenario_ids?(ids)
      add_error(:scenario_ids, 'must contain unique scenario IDs')
      return []
    end

    scenarios_by_id = assistant.scenarios.where(id: ids).index_by(&:id)
    missing_ids = ids - scenarios_by_id.keys
    add_error(:scenario_ids, "contains unavailable scenarios: #{missing_ids.join(', ')}") if missing_ids.any?
    ids.filter_map { |id| scenarios_by_id[id] }
  end

  def selected_scenario_ids
    return assistant.scenarios.enabled.pluck(:id) unless @params.key?(:scenario_ids)

    Array(@params[:scenario_ids]).map { |id| parse_id(id) }
  end

  def valid_scenario_ids?(ids)
    ids.none?(&:nil?) && ids.all?(&:positive?) && ids.uniq.length == ids.length
  end

  def parse_id(value)
    return value if value.is_a?(Integer)
    return Integer(value, exception: false) if value.is_a?(String)

    nil
  end

  def temporary_scenario_params
    Array(@params[:temporary_scenarios])
  end

  def build_temporary_scenario(attributes, index)
    attributes = temporary_scenario_attributes(attributes, index)
    client_id = attributes[:client_id].to_s.strip
    add_error("temporary_scenarios.#{index}.client_id", 'is required') if client_id.blank?

    scenario = Captain::Scenario.new(
      assistant: assistant,
      account: assistant.account,
      title: attributes[:title],
      description: attributes[:description],
      instruction: attributes[:instruction],
      enabled: true
    )
    scenario.tools = scenario.extract_tool_ids_from_text(scenario.instruction).presence
    add_temporary_scenario_errors(scenario, index)
    @temporary_metadata[scenario] = { client_id: client_id, index: index }
    scenario
  end

  def temporary_scenario_attributes(attributes, index)
    attributes = attributes.to_unsafe_h if attributes.respond_to?(:to_unsafe_h)
    return attributes.with_indifferent_access if attributes.is_a?(Hash)

    add_error("temporary_scenarios.#{index}", 'must be an object')
    {}.with_indifferent_access
  end

  def add_temporary_scenario_errors(scenario, index)
    return if scenario.valid?

    scenario.errors.each do |error|
      add_error("temporary_scenarios.#{index}.#{error.attribute}", error.message)
    end
  end

  def build_scenario_agent_names
    scenarios.each_with_object(@scenario_agent_names) do |scenario, names|
      names[scenario] = temporary?(scenario) ? temporary_agent_name(scenario) : scenario.handoff_key
    end
  end

  def temporary_agent_name(scenario)
    metadata = @temporary_metadata.fetch(scenario)
    digest = Digest::SHA256.hexdigest(metadata[:client_id])[0, 16]
    "scenario_temp_#{digest}_agent"
  end

  def validate_temporary_client_ids
    client_ids = @temporary_metadata.values.pluck(:client_id).reject(&:blank?)
    add_error(:temporary_scenarios, 'must contain unique client IDs') if client_ids.uniq.length != client_ids.length
  end

  def resolve_rules
    @response_guidelines = resolve_rule_list(:response_guidelines, assistant.response_guidelines)
    @guardrails = resolve_rule_list(:guardrails, assistant.guardrails)
  end

  def resolve_rule_list(key, persisted_rules)
    rules = @params.key?(key) ? Array(@params[key]) : Array(persisted_rules)
    normalized = rules.map { |rule| rule.to_s.strip }
    add_error(key, 'must not contain blank rules') if normalized.any?(&:blank?)
    normalized.reject(&:blank?).uniq
  end

  def resolve_knowledge
    @knowledge_text = @params[:knowledge_text].to_s
    return if knowledge_text.length <= MAX_KNOWLEDGE_LENGTH

    add_error(:knowledge_text, "is limited to #{MAX_KNOWLEDGE_LENGTH} characters")
  end

  def scenario_prompt_context
    scenarios.map do |scenario|
      {
        title: scenario.title,
        key: agent_name_for(scenario),
        description: scenario.description
      }
    end
  end

  def assistant_handler
    {
      type: 'assistant',
      id: nil,
      title: assistant.name,
      temporary: false
    }
  end

  def add_error(key, message)
    (@errors[key.to_s] ||= []) << message
  end
end
