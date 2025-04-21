module Api::V1::AiAgentTemplatesHelper
  def build_chat_flow(template, store_id, ai_agent_name)
    flow_data = template.template.deep_dup

    database_name = formatted_name(ai_agent_name)
    vector_store_node(flow_data, database_name)
    chat_memory_node(flow_data, database_name)
    document_node(flow_data, store_id)

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

  def formatted_name(ai_agent_name)
    cleaned = ai_agent_name.downcase.gsub(/[^a-z\s]/, '')
    underscored = cleaned.strip.gsub(/\s+/, '_')
    today = Time.current.strftime('%Y%m%d%H%M%S')

    "#{underscored}_#{today}"
  end
end
