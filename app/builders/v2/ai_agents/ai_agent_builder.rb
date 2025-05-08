class V2::AiAgents::AiAgentBuilder
  include ChatFlowHelper

  attr_reader :account, :params

  def initialize(account, params)
    @account = account
    @params = params
  end

  def find_all_ai_agents
    account.ai_agents.select(:id, :account_id, :name, :description)
  end

  def find_all_ai_agents_templates
    AiAgentTemplate.select(:id, :name, :template)
  end

  def find_ai_agent
    ai_agent.as_detailed_json
  end

  def build_and_create
    raise ActionController::ParameterMissing, 'AI Agent Template not found' unless ai_agent_template

    document_store = AiAgents::FlowiseService.add_document_store(ai_agent_params)

    begin
      chat_flow = load_chat_flow(document_store['id'])

      ActiveRecord::Base.transaction do
        account.ai_agents.add_ai_agent(ai_agent_params, ai_agent_template, chat_flow, document_store)
      end
    rescue StandardError => e
      AiAgents::FlowiseService.delete_chat_flow(id: chat_flow['id']) if chat_flow && chat_flow['id'].present?
      AiAgents::FlowiseService.delete_document_store(store_id: document_store['id']) if document_store && document_store['id'].present?
      raise e
    end
  end

  def destroy
    chat_flow_id = ai_agent.chat_flow_id
    store_id = ai_agent.knowledge_source&.store_id

    raise StandardError, 'Failed to delete AI Agent' unless ai_agent.destroy

    begin
      AiAgents::FlowiseService.delete_chat_flow(id: chat_flow_id) if chat_flow_id.present?
      AiAgents::FlowiseService.delete_document_store(store_id: store_id) if store_id.present?
    rescue StandardError => e
      Rails.logger.error("❌ Failed to delete chat flow: #{e.message}")
      raise 'Failed to delete chat flow'
    end
  end

  def update
    save_as_chat_flow

    ActiveRecord::Base.transaction do
      handle_selected_labels
      ai_agent.update!(ai_agent_params)
    end

    ai_agent.as_json(include: :ai_agent_selected_labels)
  rescue StandardError => e
    Rails.logger.error("❌ Failed to update AI Agent: #{e.message}")
    raise 'Failed to update AI Agent'
  end

  def template
    @template ||= ai_agent_template
  end

  private

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

  def load_chat_flow(document_store_id)
    flow_data, store_config = create_flow_data_and_store_config(document_store_id)
    response = AiAgents::FlowiseService.load_chat_flow(params[:name], flow_data)

    { 'id' => response['id'], 'flow_data' => flow_data, 'store_config' => store_config }
  rescue StandardError => e
    Rails.logger.error("❌ Failed to load chat flow: #{e.message}")
    raise e
  end

  def save_as_chat_flow
    flow_data = save_as(ai_agent)

    AiAgents::FlowiseService.save_as_chat_flow(ai_agent.chat_flow_id, ai_agent_params[:name], flow_data)
    flow_data
  rescue StandardError => e
    Rails.logger.error("❌ Failed to save chat flow: #{e.message}")
    raise e
  end

  def template_id
    params[:template_id].presence || ai_agent.template_id
  end

  def ai_agent_template
    @ai_agent_template ||= AiAgentTemplate.find_by(id: template_id)
  end

  def ai_agent
    @ai_agent ||= account.ai_agents.find(params[:id])
  end

  def selected_labels_params
    label_data = Array.wrap(params[:selected_labels])

    label_data.filter_map do |label|
      label.permit(:label_id, :label_condition) if label[:label_id].present?
    end
  end

  def ai_agent_params
    params.require(:ai_agent).permit(
      :name, :description, :template_id, :system_prompts, :welcoming_message, :routing_conditions, :control_flow_rules, :llm_model,
      :history_limit, :context_limit, :message_await, :message_limit, :timezone, selected_labels: %i[label_id label_condition]
    )
  end
end
