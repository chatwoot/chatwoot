class V2::AiAgents::ChatFlowBuilder
  attr_reader :account, :template, :params

  def initialize(account, params, template = nil)
    @account = account
    @template = template
    @params = params
  end

  def build
    default_system_message
    chat_memory
    vector_store

    flow_data
  end

  def save_as(ai_agent)
    @flow_data = ai_agent.flow_data
    system_message
    @flow_data
  end

  def store_config(store_id)
    store_config_for_document_store(store_id)
  end

  private

  def flow_data
    @flow_data ||= template&.template&.deep_dup || {}
  end

  def business_name
    @business_name ||= account.name
  end

  def database_name
    @database_name ||= formatted_name
  end

  def find_node_by_id(id)
    node = flow_data['nodes'].find { |n| n['id'] == id }
    raise KeyError, "Node not found: #{id}" unless node

    node
  end

  def default_system_message
    node = find_node_by_id('chatPromptTemplate_0')
    node['data']['inputs']['systemMessagePrompt'] = replace_business_name
  end

  def system_message
    node = find_node_by_id('chatPromptTemplate_0')
    node['data']['inputs']['systemMessagePrompt'] = params[:system_prompts]
  end

  def chat_memory
    node = find_node_by_id('MongoDBAtlasChatMemory_0')
    node['data']['inputs']['databaseName'] = database_name
  end

  def vector_store
    node = find_node_by_id('qdrant_0')
    node['data']['inputs']['qdrantCollection'] = database_name
  end

  def store_config_for_document_store(store_id)
    store_config = template.store_config.deep_dup

    store_config['storeId'] = store_id
    store_config['vectorStoreConfig']['databaseName'] = database_name
    store_config['vectorStoreConfig']['qdrantCollection'] = database_name
    store_config['recordManagerConfig']['tableName'] = "#{database_name}_upsertion_records"

    store_config
  end

  def replace_business_name
    template.welcoming_message = template.welcoming_message.gsub('{business_name}', business_name)
    template.system_prompt = template.system_prompt.gsub('{business_name}', business_name)
  end

  def formatted_name
    cleaned = params[:name].downcase.gsub(/[^a-z\s]/, '')
    underscored = cleaned.strip.gsub(/\s+/, '_')
    today = Time.current.strftime('%Y%m%d%H%M%S')

    "#{underscored}_#{today}"
  end
end
