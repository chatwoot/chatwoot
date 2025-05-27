module ChatFlowHelper
  WINDOW_SIZE = 10
  LLM_TEMPERATURE = 0.7

  def self.included(base)
    base.class_eval do
      attr_reader :account, :params
      attr_accessor :template
    end
  end

  def create_flow_data_and_store_config(store_id)
    default_system_message_prompt
    set_redis_for_chat_memory
    set_qdrant_vector_store

    [flow_data, store_config(store_id)]
  end

  def save_as(ai_agent)
    flow_data = ai_agent.flow_data
    self.flow_data = flow_data

    system_message_prompt

    flow_data
  end

  private

  def flow_data
    @flow_data ||= template&.template&.deep_dup || {}
  end

  def flow_data=(new_data)
    @flow_data = new_data
  end

  def store_config(store_id)
    store_config = template.store_config.deep_dup

    store_config['storeId'] = store_id
    store_config['vectorStoreConfig']['databaseName'] = database_name
    store_config['vectorStoreConfig']['qdrantCollection'] = database_name
    store_config['recordManagerConfig']['tableName'] = "#{database_name}_upsertion_records"

    store_config
  end

  def find_node_by_id(id)
    node = flow_data['nodes'].find { |n| n['id'] == id }
    raise KeyError, "Node not found: #{id}" unless node

    node
  end

  def default_system_message_prompt
    replace_business_name
    replace_additional_rules_for_handover_prompt
    node = find_node_by_id('chatPromptTemplate_0')
    node['data']['inputs']['systemMessagePrompt'] = "#{template.system_prompt}\n\n#{template.system_prompt_rules}"
  end

  def system_message_prompt
    replace_additional_rules_for_handover_prompt
    node = find_node_by_id('chatPromptTemplate_0')
    node['data']['inputs']['systemMessagePrompt'] = combined_system_prompt
  end

  def handover_prompt_template
    node = find_node_by_id('promptTemplate_0')
    node['data']['inputs']['template'] = replace_additional_rules_for_handover_prompt
  end

  def set_redis_for_chat_memory
    node = find_node_by_id('RedisBackedChatMemory_0')
    node['data']['inputs']['windowSize'] = WINDOW_SIZE
  end

  def set_buffer_for_chat_memory
    node = find_node_by_id('bufferWindowMemory_0')
    node['data']['inputs']['k'] = WINDOW_SIZE
  end

  def set_mongodb_atlas_chat_memory
    node = find_node_by_id('MongoDBAtlasChatMemory_0')
    node['data']['inputs']['databaseName'] = database_name
  end

  def set_qdrant_vector_store
    node = find_node_by_id('qdrant_0')
    node['data']['inputs']['qdrantCollection'] = database_name
  end

  def set_azure_openai_temperature
    %w[azureChatOpenAI_0 azureChatOpenAI_2].each do |node_id|
      find_node_by_id(node_id)['data']['inputs']['temperature'] = LLM_TEMPERATURE
    end
  end

  def replace_business_name
    template.welcoming_message = template.welcoming_message.gsub('{business_name}', business_name)
    template.system_prompt = template.system_prompt.gsub('{business_name}', business_name)
  end

  def replace_additional_rules_for_handover_prompt
    template.system_prompt_rules = template.system_prompt_rules.gsub('{additional_rules}', params[:routing_conditions] || '')
  end

  def combined_system_prompt
    "#{params[:system_prompts]}\n\n#{template.system_prompt_rules}"
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
end
