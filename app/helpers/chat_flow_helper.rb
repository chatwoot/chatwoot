module ChatFlowHelper
  WINDOW_SIZE = 10
  LLM_TEMPERATURE = 0.7

  def self.included(base)
    base.class_eval do
      attr_reader :account, :params
      attr_accessor :template
    end
  end

  def create_flow_data
    update_node_input('chatPromptTemplate_0', 'systemMessagePrompt', system_prompt)
    update_node_input('bufferWindowMemory_0', 'k', WINDOW_SIZE)
    update_node_input('qdrant_0', 'qdrantCollection', database_name)

    flow_data
  end

  def store_config(store_id)
    store_config = template.store_config.deep_dup

    store_config['storeId'] = store_id
    store_config['vectorStoreConfig']['databaseName'] = database_name
    store_config['vectorStoreConfig']['qdrantCollection'] = database_name
    store_config['recordManagerConfig']['tableName'] = "#{database_name}_upsertion_records"

    [store_config, database_name]
  end

  def save_as(ai_agent)
    flow_data = ai_agent.flow_data
    self.flow_data = flow_data

    update_node_input('chatPromptTemplate_0', 'systemMessagePrompt', combined_system_prompt)

    flow_data
  end

  private

  def flow_data
    @flow_data ||= template&.template&.deep_dup || {}
  end

  def flow_data=(new_data)
    @flow_data = new_data
  end

  def find_node_by_id(id)
    node = flow_data['nodes'].find { |n| n['id'] == id }
    raise KeyError, "Node not found: #{id}" unless node

    node
  end

  def update_node_input(node_id, input_key, input_value)
    node = find_node_by_id(node_id)
    node['data']['inputs'][input_key] = input_value
  end

  def system_prompt
    replace_placeholder

    identity = template.system_prompt
    guideline_and_task = template.system_prompt_rules

    generate_system_prompt(identity, guideline_and_task)
  end

  def set_azure_openai_temperature
    %w[azureChatOpenAI_0 azureChatOpenAI_2].each do |node_id|
      find_node_by_id(node_id)['data']['inputs']['temperature'] = LLM_TEMPERATURE
    end
  end

  def replace_placeholder
    template.welcoming_message = multi_gsub(template.welcoming_message, placeholders)
    template.system_prompt = multi_gsub(template.system_prompt, placeholders)
    template.system_prompt_rules = multi_gsub(template.system_prompt_rules, placeholders)
  end

  def combined_system_prompt
    identity = params[:flow_data]&.dig('agents_config', 0, 'bot_prompt')
    guideline_and_task = multi_gsub(template.system_prompt_rules, placeholders)
    generate_system_prompt(identity, guideline_and_task)
  end

  def placeholders
    {
      '{business_name}' => business_name,
      '{additional_rules}' => params[:routing_conditions] || ''
    }
  end

  def multi_gsub(str, replacements)
    replacements.reduce(str) { |result, (pattern, value)| result.gsub(pattern, value) }
  end

  def business_name
    @business_name ||= account.name
  end

  def database_name
    @database_name ||= formatted_name
  end

  def formatted_name
    cleaned = params[:name].downcase.gsub(/[^a-z\s]/, '')
    underscored = cleaned.strip.gsub(/\s+/, '_')
    today = Time.current.strftime('%Y%m%d%H%M%S')

    "#{underscored}_#{today}"
  end

  def generate_system_prompt(identity, guideline_and_task)
    Captain::Llm::SystemPromptService.new.generate_system_prompt(identity, guideline_and_task)
  end
end
