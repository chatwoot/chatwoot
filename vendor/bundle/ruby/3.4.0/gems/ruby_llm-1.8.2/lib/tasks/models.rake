# frozen_string_literal: true

require 'dotenv/load'
require 'ruby_llm'
require 'json'
require 'json-schema'
require 'fileutils'

desc 'Update models, docs, and aliases'
task models: ['models:update', 'models:docs', 'models:aliases']

namespace :models do
  desc 'Update available models from providers (API keys needed)'
  task :update do
    puts 'Configuring RubyLLM...'
    configure_from_env
    refresh_models
    display_model_stats
  end

  desc 'Generate available models documentation'
  task :docs do
    FileUtils.mkdir_p('docs/_reference')
    output = generate_models_markdown
    File.write('docs/_reference/available-models.md', output)
    puts 'Generated docs/_reference/available-models.md'
  end

  desc 'Generate model aliases from registry'
  task :aliases do
    generate_aliases
  end
end

# Keep aliases:generate for backwards compatibility
namespace :aliases do
  task generate: ['models:aliases']
end

def configure_from_env
  RubyLLM.configure do |config|
    config.openai_api_key = ENV.fetch('OPENAI_API_KEY', nil)
    config.anthropic_api_key = ENV.fetch('ANTHROPIC_API_KEY', nil)
    config.gemini_api_key = ENV.fetch('GEMINI_API_KEY', nil)
    config.deepseek_api_key = ENV.fetch('DEEPSEEK_API_KEY', nil)
    config.perplexity_api_key = ENV.fetch('PERPLEXITY_API_KEY', nil)
    config.openrouter_api_key = ENV.fetch('OPENROUTER_API_KEY', nil)
    config.mistral_api_key = ENV.fetch('MISTRAL_API_KEY', nil)
    config.vertexai_location = ENV.fetch('GOOGLE_CLOUD_LOCATION', nil)
    config.vertexai_project_id = ENV.fetch('GOOGLE_CLOUD_PROJECT', nil)
    configure_bedrock(config)
    config.request_timeout = 30
  end
end

def configure_bedrock(config)
  config.bedrock_api_key = ENV.fetch('AWS_ACCESS_KEY_ID', nil)
  config.bedrock_secret_key = ENV.fetch('AWS_SECRET_ACCESS_KEY', nil)
  config.bedrock_region = ENV.fetch('AWS_REGION', nil)
  config.bedrock_session_token = ENV.fetch('AWS_SESSION_TOKEN', nil)
end

def refresh_models
  initial_count = RubyLLM.models.all.size
  puts "Refreshing models (#{initial_count} cached)..."

  models = RubyLLM.models.refresh!

  if models.all.empty? && initial_count.zero?
    puts 'Error: Failed to fetch models.'
    exit(1)
  elsif models.all.size == initial_count && initial_count.positive?
    puts 'Warning: Model list unchanged.'
  else
    puts 'Validating models...'
    validate_models!(models)

    puts "Saving models.json (#{models.all.size} models)"
    models.save_to_json
  end

  @models = models
end

def validate_models!(models)
  schema_path = RubyLLM::Models.schema_file
  models_data = models.all.map(&:to_h)

  validation_errors = JSON::Validator.fully_validate(schema_path, models_data)

  unless validation_errors.empty?
    # Save failed models for inspection
    failed_path = File.expand_path('../ruby_llm/models.failed.json', __dir__)
    File.write(failed_path, JSON.pretty_generate(models_data))

    puts 'ERROR: Models validation failed:'
    puts "\nValidation errors:"
    validation_errors.first(10).each { |error| puts "  - #{error}" }
    puts "  ... and #{validation_errors.size - 10} more errors" if validation_errors.size > 10
    puts "-> Failed models saved to: #{failed_path}"
    exit(1)
  end

  puts '✓ Models validation passed'
end

def display_model_stats
  puts "\nModel count:"
  provider_counts = @models.all.group_by(&:provider).transform_values(&:count)

  RubyLLM::Provider.providers.each do |sym, provider_class|
    name = provider_class.name
    count = provider_counts[sym.to_s] || 0
    status = status(sym)
    puts "  #{name}: #{count} models #{status}"
  end

  puts 'Refresh complete.'
end

def status(provider_sym)
  provider_class = RubyLLM::Provider.providers[provider_sym]
  if provider_class.local?
    ' (LOCAL - SKIP)'
  elsif provider_class.configured?(RubyLLM.config)
    ' (OK)'
  else
    ' (NOT CONFIGURED)'
  end
end

def generate_models_markdown
  <<~MARKDOWN
    ---
    layout: default
    title: Available Models
    nav_order: 1
    description: Browse hundreds of AI models from every major provider. Always up-to-date, automatically generated.
    redirect_from:
      - /guides/available-models
    ---

    # {{ page.title }}
    {: .no_toc }

    {{ page.description }}
    {: .fs-6 .fw-300 }

    ## Table of contents
    {: .no_toc .text-delta }

    1. TOC
    {:toc}

    ---

    ## Model Data Sources

    - **OpenAI, Anthropic, DeepSeek, Gemini, VertexAI**: Enriched by [🚀 Parsera](https://parsera.org/) *([free LLM metadata API](https://api.parsera.org/v1/llm-specs) - [go say thanks!](https://github.com/parsera-labs/api-llm-specs))*
    - **OpenRouter**: Direct API
    - **Others**: Local capabilities files

    ## Last Updated
    {: .d-inline-block }

    #{Time.now.utc.strftime('%Y-%m-%d')}
    {: .label .label-green }

    ## Models by Provider

    #{generate_provider_sections}

    ## Models by Capability

    #{generate_capability_sections}

    ## Models by Modality

    #{generate_modality_sections}
  MARKDOWN
end

def generate_provider_sections
  RubyLLM::Provider.providers.filter_map do |provider, provider_class|
    models = RubyLLM.models.by_provider(provider)
    next if models.none?

    <<~PROVIDER
      ### #{provider_class.name} (#{models.count})

      #{models_table(models)}
    PROVIDER
  end.join("\n\n")
end

def generate_capability_sections
  capabilities = {
    'Function Calling' => RubyLLM.models.select(&:function_calling?),
    'Structured Output' => RubyLLM.models.select(&:structured_output?),
    'Streaming' => RubyLLM.models.select { |m| m.capabilities.include?('streaming') },
    'Batch Processing' => RubyLLM.models.select { |m| m.capabilities.include?('batch') }
  }

  capabilities.filter_map do |capability, models|
    next if models.none?

    <<~CAPABILITY
      ### #{capability} (#{models.count})

      #{models_table(models)}
    CAPABILITY
  end.join("\n\n")
end

def generate_modality_sections # rubocop:disable Metrics/PerceivedComplexity
  sections = []

  vision_models = RubyLLM.models.select { |m| (m.modalities.input || []).include?('image') }
  if vision_models.any?
    sections << <<~SECTION
      ### Vision Models (#{vision_models.count})

      Models that can process images:

      #{models_table(vision_models)}
    SECTION
  end

  audio_models = RubyLLM.models.select { |m| (m.modalities.input || []).include?('audio') }
  if audio_models.any?
    sections << <<~SECTION
      ### Audio Input Models (#{audio_models.count})

      Models that can process audio:

      #{models_table(audio_models)}
    SECTION
  end

  pdf_models = RubyLLM.models.select { |m| (m.modalities.input || []).include?('pdf') }
  if pdf_models.any?
    sections << <<~SECTION
      ### PDF Models (#{pdf_models.count})

      Models that can process PDF documents:

      #{models_table(pdf_models)}
    SECTION
  end

  embedding_models = RubyLLM.models.select { |m| (m.modalities.output || []).include?('embeddings') }
  if embedding_models.any?
    sections << <<~SECTION
      ### Embedding Models (#{embedding_models.count})

      Models that generate embeddings:

      #{models_table(embedding_models)}
    SECTION
  end

  sections.join("\n\n")
end

def models_table(models)
  return '*No models found*' if models.none?

  headers = ['Model', 'Provider', 'Context', 'Max Output', 'Standard Pricing (per 1M tokens)']
  alignment = [':--', ':--', '--:', '--:', ':--']

  rows = models.sort_by { |m| [m.provider, m.name] }.map do |model|
    pricing = standard_pricing_display(model)

    [
      model.id,
      model.provider,
      model.context_window || '-',
      model.max_output_tokens || '-',
      pricing
    ]
  end

  table = []
  table << "| #{headers.join(' | ')} |"
  table << "| #{alignment.join(' | ')} |"

  rows.each do |row|
    table << "| #{row.join(' | ')} |"
  end

  table.join("\n")
end

def standard_pricing_display(model)
  pricing_data = model.pricing.to_h[:text_tokens]&.dig(:standard) || {}

  if pricing_data.any?
    parts = []

    parts << "In: $#{format('%.2f', pricing_data[:input_per_million])}" if pricing_data[:input_per_million]

    parts << "Out: $#{format('%.2f', pricing_data[:output_per_million])}" if pricing_data[:output_per_million]

    if pricing_data[:cached_input_per_million]
      parts << "Cache: $#{format('%.2f', pricing_data[:cached_input_per_million])}"
    end

    return parts.join(', ') if parts.any?
  end

  '-'
end

def generate_aliases # rubocop:disable Metrics/PerceivedComplexity
  models = Hash.new { |h, k| h[k] = [] }

  RubyLLM.models.all.each do |model|
    models[model.provider] << model.id
  end

  aliases = {}

  # OpenAI models
  models['openai'].each do |model|
    openrouter_model = "openai/#{model}"
    next unless models['openrouter'].include?(openrouter_model)

    alias_key = model.gsub('-latest', '')
    aliases[alias_key] = {
      'openai' => model,
      'openrouter' => openrouter_model
    }
  end

  anthropic_latest = group_anthropic_models_by_base_name(models['anthropic'])

  anthropic_latest.each do |base_name, latest_model|
    openrouter_variants = [
      "anthropic/#{base_name}",
      "anthropic/#{base_name.gsub(/-(\d)/, '.\1')}",
      "anthropic/#{base_name.gsub(/claude-(\d+)-(\d+)/, 'claude-\1.\2')}",
      "anthropic/#{base_name.gsub(/(\d+)-(\d+)/, '\1.\2')}"
    ]

    openrouter_model = openrouter_variants.find { |v| models['openrouter'].include?(v) }
    bedrock_model = find_best_bedrock_model(latest_model, models['bedrock'])

    next unless openrouter_model || bedrock_model || models['anthropic'].include?(latest_model)

    aliases[base_name] = { 'anthropic' => latest_model }
    aliases[base_name]['openrouter'] = openrouter_model if openrouter_model
    aliases[base_name]['bedrock'] = bedrock_model if bedrock_model
  end

  models['bedrock'].each do |bedrock_model|
    next unless bedrock_model.start_with?('anthropic.')
    next unless bedrock_model =~ /anthropic\.(claude-[\d.]+-[a-z]+)/

    base_name = Regexp.last_match(1)
    anthropic_name = base_name.tr('.', '-')

    next if aliases[anthropic_name]

    openrouter_variants = [
      "anthropic/#{anthropic_name}",
      "anthropic/#{base_name}"
    ]

    openrouter_model = openrouter_variants.find { |v| models['openrouter'].include?(v) }

    aliases[anthropic_name] = { 'bedrock' => bedrock_model }
    aliases[anthropic_name]['anthropic'] = anthropic_name if models['anthropic'].include?(anthropic_name)
    aliases[anthropic_name]['openrouter'] = openrouter_model if openrouter_model
  end

  # Gemini models (also map to vertexai)
  models['gemini'].each do |model|
    openrouter_variants = [
      "google/#{model}",
      "google/#{model.gsub('gemini-', 'gemini-').tr('.', '-')}",
      "google/#{model.gsub('gemini-', 'gemini-')}"
    ]

    openrouter_model = openrouter_variants.find { |v| models['openrouter'].include?(v) }
    vertexai_model = models['vertexai'].include?(model) ? model : nil

    next unless openrouter_model || vertexai_model

    alias_key = model.gsub('-latest', '')
    aliases[alias_key] = { 'gemini' => model }
    aliases[alias_key]['openrouter'] = openrouter_model if openrouter_model
    aliases[alias_key]['vertexai'] = vertexai_model if vertexai_model
  end

  # VertexAI models that aren't in Gemini (e.g. older models like text-bison)
  models['vertexai'].each do |model|
    # Skip if already handled above
    next if models['gemini'].include?(model)

    # Check if OpenRouter has this Google model
    openrouter_variants = [
      "google/#{model}",
      "google/#{model.tr('.', '-')}"
    ]

    openrouter_model = openrouter_variants.find { |v| models['openrouter'].include?(v) }
    gemini_model = models['gemini'].include?(model) ? model : nil

    next unless openrouter_model || gemini_model

    alias_key = model.gsub('-latest', '')
    next if aliases[alias_key] # Skip if already created

    aliases[alias_key] = { 'vertexai' => model }
    aliases[alias_key]['openrouter'] = openrouter_model if openrouter_model
    aliases[alias_key]['gemini'] = gemini_model if gemini_model
  end

  models['deepseek'].each do |model|
    openrouter_model = "deepseek/#{model}"
    next unless models['openrouter'].include?(openrouter_model)

    alias_key = model.gsub('-latest', '')
    aliases[alias_key] = {
      'deepseek' => model,
      'openrouter' => openrouter_model
    }
  end

  sorted_aliases = aliases.sort.to_h
  File.write(RubyLLM::Aliases.aliases_file, JSON.pretty_generate(sorted_aliases))

  puts "Generated #{sorted_aliases.size} aliases"
end

def group_anthropic_models_by_base_name(anthropic_models)
  grouped = Hash.new { |h, k| h[k] = [] }

  anthropic_models.each do |model|
    base_name = extract_base_name(model)
    grouped[base_name] << model
  end

  latest_models = {}
  grouped.each do |base_name, model_list|
    if model_list.size == 1
      latest_models[base_name] = model_list.first
    else
      latest_model = model_list.max_by { |model| extract_date_from_model(model) }
      latest_models[base_name] = latest_model
    end
  end

  latest_models
end

def extract_base_name(model)
  if model =~ /^(.+)-(\d{8})$/
    Regexp.last_match(1)
  else
    model
  end
end

def extract_date_from_model(model)
  if model =~ /-(\d{8})$/
    Regexp.last_match(1)
  else
    '00000000'
  end
end

def find_best_bedrock_model(anthropic_model, bedrock_models) # rubocop:disable Metrics/PerceivedComplexity
  base_pattern = case anthropic_model
                 when 'claude-2.0', 'claude-2'
                   'claude-v2'
                 when 'claude-2.1'
                   'claude-v2:1'
                 when 'claude-instant-v1', 'claude-instant'
                   'claude-instant'
                 else
                   extract_base_name(anthropic_model)
                 end

  matching_models = bedrock_models.select do |bedrock_model|
    model_without_prefix = bedrock_model.sub(/^(?:us\.)?anthropic\./, '')
    model_without_prefix.start_with?(base_pattern)
  end

  return nil if matching_models.empty?

  begin
    model_info = RubyLLM.models.find(anthropic_model)
    target_context = model_info.context_window
  rescue StandardError
    target_context = nil
  end

  if target_context
    target_k = target_context / 1000

    with_context = matching_models.select do |m|
      m.include?(":#{target_k}k") || m.include?(":0:#{target_k}k")
    end

    return with_context.first if with_context.any?
  end

  matching_models.min_by do |model|
    context_priority = if model =~ /:(?:\d+:)?(\d+)k/
                         -Regexp.last_match(1).to_i
                       else
                         0
                       end

    version_priority = if model =~ /-v(\d+):/
                         -Regexp.last_match(1).to_i
                       else
                         0
                       end

    has_context_priority = model.include?('k') ? -1 : 0
    [has_context_priority, context_priority, version_priority]
  end
end
