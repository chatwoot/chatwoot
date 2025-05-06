module Api::V1::AiAgentTemplatesHelper
  def build_chat_flow(template, store_id, ai_agent_name, business_name)
    flow_data = template.template.deep_dup

    database_name = formatted_name(ai_agent_name)
    vector_store_node(flow_data, database_name)
    chat_memory_node(flow_data, database_name)
    document_node(flow_data, store_id)
    system_message(flow_data, template, business_name)

    store_config = set_store_config(store_id, database_name, template)

    { flow_data: flow_data, store_config: store_config }
  end

  def save_as_chat_flow(system_prompt, flow_data)
    flow_data['nodes'].each do |node|
      if node['data']['name'] == 'toolAgent'
        node['data']['inputs']['systemMessage'] = system_prompt
        # node['data']['inputs']['welcomingMessage'] = welcoming_message
      end
    end

    flow_data
  end

  def find_node_by_name(flow_data, name)
    flow_data['nodes'].find { |n| n['data']['name'] == name }
  end

  def vector_store_node(flow_data, database_name)
    node = find_node_by_name(flow_data, 'mongoDBAtlas')
    node['data']['inputs']['databaseName'] = database_name
    node['data']['inputs']['collectionName'] = 'vectors'
  end

  def chat_memory_node(flow_data, database_name)
    node = find_node_by_name(flow_data, 'MongoDBAtlasChatMemory')
    node['data']['inputs']['databaseName'] = database_name
    node['data']['inputs']['collectionName'] = 'chat_memories'
  end

  def document_node(flow_data, store_id)
    node = find_node_by_name(flow_data, 'documentStore')
    node['data']['inputs']['selectedStore'] = store_id
  end

  def system_message(flow_data, template, business_name)
    node = find_node_by_name(flow_data, 'toolAgent')
    node['data']['inputs']['systemMessage'] = replace_business_name(template, business_name)
  end

  def replace_business_name(template, business_name)
    template.welcoming_message = template.welcoming_message.gsub('{business_name}', business_name)
    template.system_prompt = template.system_prompt.gsub('{business_name}', business_name)
  end

  def formatted_name(ai_agent_name)
    cleaned = ai_agent_name.downcase.gsub(/[^a-z\s]/, '')
    underscored = cleaned.strip.gsub(/\s+/, '_')
    today = Time.current.strftime('%Y%m%d%H%M%S')

    "#{underscored}_#{today}"
  end

  def set_store_config(store_id, database_name, template)
    store_config = template.store_config.deep_dup

    store_config['storeId'] = store_id
    store_config['vectorStoreConfig']['databaseName'] = database_name

    store_config
  end
end
