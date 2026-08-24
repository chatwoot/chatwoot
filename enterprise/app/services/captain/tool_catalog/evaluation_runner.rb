require 'digest'

class Captain::ToolCatalog::EvaluationRunner
  CONFIG_ROOT = Rails.root.join('enterprise/config/captain/tool_catalog/evals').freeze
  DATASET_PATH = CONFIG_ROOT.join('support_intents.json').freeze
  BASELINE_PATH = CONFIG_ROOT.join('baseline_tools.json').freeze
  DISTRACTOR_PATH = CONFIG_ROOT.join('distractor_tools.json').freeze
  CROSS_CUSTOMER_PROVIDERS = %w[shopify stripe].freeze
  CUSTOMER_IDENTITY_KEY = /\A(?:customer_?id|contact_?id|email|phone|phone_number)\z/i
  INSTRUCTIONS = <<~PROMPT.freeze
    You route customer-support requests to tools. Call exactly one tool that best satisfies the request.
    Prefer the narrowest tool whose description directly matches the request. Never invent or call an unrelated action.
  PROMPT

  def initialize(model:, registry: Captain::ToolCatalog::ProviderPackRegistry.default, chat_factory: nil)
    @model = model
    @registry = registry
    @chat_factory = chat_factory || method(:build_chat)
  end

  def validation_summary
    validate!
    {
      'dataset_size' => dataset.length,
      'dataset_digest' => dataset_digest,
      'baseline_tool_count' => baseline_definitions.length,
      'candidate_tool_count' => candidate_definitions.length,
      'non_available_tools_exposed' => all_definitions.count { |definition| definition['availability'] != 'available' }
    }
  end

  def perform
    validate!
    report = {
      'schema_version' => 1,
      'generated_at' => Time.current.utc.iso8601,
      'model' => model,
      'dataset' => { 'size' => dataset.length, 'digest' => dataset_digest },
      'runs' => {
        'baseline' => run_configuration(baseline_definitions),
        'candidate' => run_configuration(candidate_definitions)
      }
    }
    report['gate'] = Captain::ToolCatalog::EvaluationGate.new(report).result
    report
  end

  private

  attr_reader :model, :registry, :chat_factory

  def validate!
    validate_dataset!
    validate_tool_counts!
    validate_expected_tools!
    validate_tool_availability!
  end

  def validate_dataset!
    raise ArgumentError, 'evaluation_dataset_too_small' if dataset.length < Captain::ToolCatalog::EvaluationGate::MINIMUM_INTENTS
    raise ArgumentError, 'duplicate_evaluation_intents' if dataset.pluck('id').uniq.length != dataset.length
  end

  def validate_tool_counts!
    raise ArgumentError, 'baseline_tool_count_invalid' unless baseline_definitions.length == 15
    raise ArgumentError, 'candidate_tool_count_invalid' unless candidate_definitions.length == 50
  end

  def validate_expected_tools!
    expected_tools = dataset.pluck('expected_tool').uniq
    missing_expected_tools = expected_tools - baseline_definitions.pluck('name')
    raise ArgumentError, "baseline_expected_tools_missing:#{missing_expected_tools.sort.join(',')}" if missing_expected_tools.any?
  end

  def validate_tool_availability!
    raise ArgumentError, 'non_available_evaluation_tool' if all_definitions.any? { |definition| definition['availability'] != 'available' }
  end

  def run_configuration(definitions)
    {
      'tool_count' => definitions.length,
      'non_available_tools_exposed' => definitions.count { |definition| definition['availability'] != 'available' },
      'cases' => dataset.map { |intent| run_intent(intent, definitions) }
    }
  end

  def run_intent(intent, definitions)
    selected_calls = []
    chat = chat_factory.call(model).with_temperature(0).with_instructions(INSTRUCTIONS)
    definitions.each { |definition| chat = chat.with_tool(Captain::ToolCatalog::EvaluationTool.new(definition)) }
    chat.on_tool_call { |tool_call| selected_calls << tool_call }
    chat.ask(intent.fetch('prompt'))

    result = case_result(intent, definitions, selected_calls.first)
    selected_calls.many? ? result.merge('runner_error' => 'MultipleToolCalls') : result
  rescue StandardError => e
    case_result(intent, definitions, selected_calls&.first).merge('runner_error' => e.class.name)
  end

  def case_result(intent, definitions, selected_call)
    selected_name = selected_call&.name&.to_s
    definition = definitions.find { |candidate| candidate.fetch('name') == selected_name }
    arguments = selected_call&.arguments.to_h.deep_stringify_keys
    {
      'intent_id' => intent.fetch('id'),
      'prompt_digest' => "sha256:#{Digest::SHA256.hexdigest(intent.fetch('prompt'))}",
      'expected_tool' => intent.fetch('expected_tool'),
      'selected_tool' => selected_name,
      'correct' => selected_name == intent.fetch('expected_tool'),
      'provider_schema_rejection' => schema_rejection?(definition, arguments),
      'cross_customer_violation' => cross_customer_violation?(definition, arguments),
      'runner_error' => nil
    }
  end

  def schema_rejection?(definition, arguments)
    return false if definition.blank?

    !JSONSchemer.schema(definition.fetch('input_schema')).valid?(arguments)
  end

  def cross_customer_violation?(definition, arguments)
    return false unless CROSS_CUSTOMER_PROVIDERS.include?(definition&.fetch('provider', nil))

    nested_keys(arguments).any? { |key| key.match?(CUSTOMER_IDENTITY_KEY) }
  end

  def nested_keys(value)
    case value
    when Hash
      value.flat_map { |key, nested| [key.to_s] + nested_keys(nested) }
    when Array
      value.flat_map { |nested| nested_keys(nested) }
    else
      []
    end
  end

  def build_chat(selected_model)
    Llm::Config.initialize!
    RubyLLM.chat(model: selected_model)
  end

  def dataset
    @dataset ||= JSON.parse(DATASET_PATH.read).fetch('intents')
  end

  def dataset_digest
    @dataset_digest ||= "sha256:#{Digest::SHA256.file(DATASET_PATH).hexdigest}"
  end

  def baseline_definitions
    @baseline_definitions ||= begin
      names = JSON.parse(BASELINE_PATH.read).fetch('tools')
      definitions_by_name = catalog_definitions.index_by { |definition| definition.fetch('name') }
      names.map { |name| definitions_by_name.fetch(name) }
    end
  end

  def candidate_definitions
    @candidate_definitions ||= catalog_definitions + distractor_definitions
  end

  def all_definitions
    @all_definitions ||= (baseline_definitions + candidate_definitions).uniq { |definition| definition.fetch('name') }
  end

  def catalog_definitions
    return @catalog_definitions if defined?(@catalog_definitions)

    definitions = registry.all.flat_map do |pack|
      pack.fetch('templates').filter_map do |template|
        next unless template.fetch('model_visible')

        {
          'name' => template.fetch('stable_name'),
          'description' => template.fetch('description'),
          'input_schema' => template.fetch('input_schema'),
          'provider' => pack.dig('provider', 'key'),
          'availability' => template.fetch('availability')
        }
      end
    end
    @catalog_definitions = definitions.sort_by { |definition| definition.fetch('name') }
  end

  def distractor_definitions
    @distractor_definitions ||= JSON.parse(DISTRACTOR_PATH.read).fetch('tools')
  end
end
