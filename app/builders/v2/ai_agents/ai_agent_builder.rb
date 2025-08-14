class V2::AiAgents::AiAgentBuilder < V2::AiAgents::AiAgentBaseBuilder
  private

  def create
    raise ActionController::ParameterMissing, 'AI Agent Template not found' unless ai_agent_templates

    document_store = AiAgents::FlowiseService.add_document_store(ai_agent_params)

    begin
      chat_flow = build_flow_data(document_store['id'])

      ActiveRecord::Base.transaction do
        account.ai_agents.add_ai_agent(ai_agent_params, chat_flow, document_store)
      end
    rescue StandardError => e
      Rails.logger.error("❌ Failed to create AI Agent: #{e.message}")
      cleanup_resources(document_store)
      raise e
    end
  end

  def destroy
    store_id = ai_agent.knowledge_source&.store_id

    raise StandardError, 'Failed to delete AI Agent' unless ai_agent.destroy

    begin
      cleanup_resources(store_id)
    rescue StandardError => e
      Rails.logger.error("❌ Failed to delete chat flow: #{e.message}")
      raise 'Failed to delete chat flow'
    end
  end

  def update
    update_chat_flow

    ActiveRecord::Base.transaction do
      ai_agent.update!(ai_agent_params.merge(display_flow_data: ai_agent_params[:flow_data]))
    end

    ai_agent.as_create_json
  rescue StandardError => e
    Rails.logger.error("❌ Failed to update AI Agent: #{e.message}")
    raise 'Failed to update AI Agent'
  end

  def build_flow_data(document_store_id)
    store_config, collection_name = flowise_builder.store_config(document_store_id)
    flow_data = jangkau_builder.perform(collection_name)

    build_response(flow_data, store_config)
  rescue StandardError => e
    Rails.logger.error("❌ Failed to load chat flow: #{e.message}")
    raise e
  end

  def update_chat_flow
    update_flowise_chat_flow if flowise_template?
  rescue StandardError => e
    Rails.logger.error("❌ Failed to save chat flow: #{e.message}")
    raise e
  end

  def cleanup_resources(document_store)
    cleanup_document_store(document_store)
  end

  def cleanup_document_store(document_store)
    store_id = extract_id(document_store)
    return if store_id.blank?

    AiAgents::FlowiseService.delete_document_store(store_id: store_id)
  end

  def update_flowise_chat_flow
    flow_data = flowise_builder.save_as(ai_agent)

    chat_flow_name = generate_chat_flow_name
    AiAgents::FlowiseService.save_as_chat_flow(ai_agent.chat_flow_id, chat_flow_name, flow_data)
  end

  def generate_chat_flow_name
    environment_prefix = production_environment? ? 'PROD' : 'DEV'
    "#{environment_prefix} - #{ai_agent_params[:name]}"
  end

  def build_response(flow_data, store_config)
    {
      'flow_data' => flow_data,
      'display_flow_data' => flow_data,
      'store_config' => store_config
    }
  end

  def extract_id(resource)
    case resource
    when Hash
      resource['id'] || resource[:id]
    when String, Integer
      resource
    end
  end

  def flowise_builder
    @flowise_builder ||= V2::AiAgents::FlowData::FlowiseBuilder.new(
      account,
      ai_agent_templates,
      ai_agent_params
    )
  end

  def jangkau_builder
    @jangkau_builder ||= V2::AiAgents::FlowData::JangkauBuilder.new(
      account,
      ai_agent_templates,
      ai_agent_params
    )
  end

  def handle_selected_labels
    return ai_agent.ai_agent_selected_labels.destroy_all if selected_labels_params.blank?

    valid_labels = valid_labels_from_selected
    incoming_ids = valid_labels.map { |label| label[:label_id].to_s }

    remove_unwanted_labels(incoming_ids)

    valid_labels.each { |label| update_or_create_selected_label(label) }
  end

  def valid_labels_from_selected
    selected_labels_params.reject { |label| label[:label_id].blank? }
  end

  def remove_unwanted_labels(incoming_ids)
    ai_agent.ai_agent_selected_labels.where.not(label_id: incoming_ids).destroy_all
  end

  def update_or_create_selected_label(label)
    selected_label = ai_agent.ai_agent_selected_labels.find_or_initialize_by(label_id: label[:label_id])
    selected_label.label_condition = label[:label_condition]
    selected_label.save!
  end

  def template_id
    params[:template_id].presence || ai_agent.template_id
  end

  def template_ids
    params[:template_ids].presence || ai_agent.template_id
  end

  def ai_agent_template
    @ai_agent_template ||= AiAgentTemplate.find_by(id: template_id)
  end

  def ai_agent_templates
    @ai_agent_templates ||= AiAgentTemplate.where(id: template_ids)
  end

  def ai_agent
    @ai_agent ||= account.ai_agents.find(params[:id])
  end

  def production_environment?
    ENV.fetch('RAILS_ENV', nil) == 'production'
  end

  def selected_labels_params
    label_data = Array.wrap(params[:selected_labels])

    label_data.filter_map do |label|
      label.permit(:label_id, :label_condition) if label[:label_id].present?
    end
  end

  def ai_agent_params
    @ai_agent_params ||= params.require(:ai_agent).permit(
      :name, :description, :template_id, :template_ids, :template_type, :agent_type,
      :system_prompts, :welcoming_message, :routing_conditions, :control_flow_rules,
      :llm_model, :history_limit, :context_limit, :message_await, :message_limit, :timezone,
      flow_data: {}, selected_labels: %i[label_id label_condition]
    ).to_h.with_indifferent_access
  end
end
