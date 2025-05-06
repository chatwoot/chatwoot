class Api::V1::Accounts::AiAgentsController < Api::V1::Accounts::BaseController
  include Api::V1::AiAgentTemplatesHelper
  before_action :check_max_ai_agents, only: [:create]
  before_action :set_ai_agent, only: %i[show update destroy]

  def index
    @ai_agents = Current.account.ai_agents.select(:id, :account_id, :name, :description)
    render json: @ai_agents
  end

  def show
    render json: @ai_agent.as_detailed_json
  end

  def create
    ai_agent_template = find_template
    begin
      document_store = add_document_store
      chat_flow = load_chat_flow(ai_agent_template, document_store['id'])

      ActiveRecord::Base.transaction do
        @ai_agent = build_ai_agent(ai_agent_template, chat_flow, document_store)
        @ai_agent.save!

        render json: @ai_agent, status: :created
      end
    rescue StandardError => e
      # Rollback transaction if any error occurs
      AiAgents::FlowiseService.delete_chat_flow(id: chat_flow['id']) if chat_flow && chat_flow['id'].present?
      AiAgents::FlowiseService.delete_document_store(store_id: document_store['id']) if document_store && document_store['id'].present?

      handle_error('Failed to create AI Agent', exception: e)
    end
  end

  def update
    chat_flow = update_chat_flow

    if @ai_agent.update(ai_agent_params.merge(flow_data: chat_flow['flow_data']))
      update_selected_labels if params[:ai_agent].key?(:selected_labels)

      render json: @ai_agent.as_json(include: :ai_agent_selected_labels)
    else
      handle_error('Failed to update AI Agent')
    end
  end

  def destroy
    chat_flow_id = @ai_agent.chat_flow_id
    store_id = @ai_agent.knowledge_source&.store_id

    if @ai_agent.destroy
      begin
        AiAgents::FlowiseService.delete_chat_flow(id: chat_flow_id) if chat_flow_id.present?
        AiAgents::FlowiseService.delete_document_store(store_id: store_id) if store_id.present?
      rescue StandardError => e
        handle_error('Failed to delete chat flow', status: :bad_request, exception: e)
        return
      end
      head :no_content
    else
      handle_error('Failed to delete AI Agent')
    end
  end

  def ai_agent_templates
    agent_templates = AiAgentTemplate.select(:id, :name, :template)
    render json: agent_templates, status: :ok
  end

  private

  def check_max_ai_agents
    render_error('Maximum number of AI agents reached') unless Current.account.ai_agents.count < Current.account.current_max_ai_agents
  end

  def find_template
    AiAgentTemplate.find_by(id: params[:ai_agent][:template_id]).tap do |template|
      render_error('AI Agent Template not found', :not_found) unless template
    end
  end

  def load_chat_flow(template, store_id)
    chat_flow_builder = V2::AiAgents::ChatFlowBuilder.new(Current.account, ai_agent_params, template)
    flow_data = chat_flow_builder.build
    store_config = chat_flow_builder.store_config(store_id)

    response = AiAgents::FlowiseService.load_chat_flow(
      name: ai_agent_params[:name],
      flow_data: flow_data
    )

    Rails.logger.info("✅ Chat flow loaded successfully: #{response['id']}")

    { 'id' => response['id'], 'flow_data' => flow_data, 'store_config' => store_config }
  rescue StandardError => e
    Rails.logger.error("❌ Failed to load chat flow: #{e.message}")
    raise e
  end

  def update_chat_flow
    flow_data = V2::AiAgents::ChatFlowBuilder.new(Current.account, ai_agent_params).save_as(@ai_agent)

    AiAgents::FlowiseService.save_as_chat_flow(
      id: @ai_agent.chat_flow_id,
      name: ai_agent_params[:name],
      flow_data: flow_data
    )
    { 'id' => @ai_agent.chat_flow_id, 'flow_data' => flow_data }
  rescue StandardError => e
    handle_error('Failed to save chat flow', status: :bad_gateway, exception: e)
    nil
  end

  def add_document_store
    name_with_datetime = "#{ai_agent_params[:name]} - #{Time.current.strftime('%Y%m%d%H%M%S')}"

    document_store = AiAgents::FlowiseService.add_document_store(
      name: name_with_datetime,
      description: ai_agent_params[:description]
    )

    Rails.logger.info("✅ Document store added successfully: #{name_with_datetime}")
    document_store
  rescue StandardError => e
    Rails.logger.error("❌ Failed to add document store: #{e.message}")
    raise e
  end

  def build_ai_agent(template, chat_flow, document_store)
    agent = Current.account.ai_agents.new(
      ai_agent_params.merge(
        system_prompts: template.system_prompt,
        welcoming_message: template.welcoming_message,
        flow_data: chat_flow['flow_data'],
        chat_flow_id: chat_flow['id']
      )
    )

    agent.build_knowledge_source(
      name: document_store['name'],
      store_id: document_store['id'],
      store_config: chat_flow['store_config']
    )

    agent
  end

  def update_selected_labels
    label_data = Array.wrap(params.dig(:ai_agent, :selected_labels))
    return if label_data.blank?

    ActiveRecord::Base.transaction do
      @ai_agent.ai_agent_selected_labels.destroy_all
      label_data.each do |label_entry|
        @ai_agent.ai_agent_selected_labels.create!(
          label_id: label_entry[:label_id],
          label_condition: label_entry[:label_condition]
        )
      end
    end
  end

  def set_ai_agent
    @ai_agent = Current.account.ai_agents.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error('AI Agent not found', :not_found)
  end

  def handle_error(message, status: :bad_request, exception: nil)
    Rails.logger.error("#{message}: #{exception&.message}") # Use safe navigation operator
    render_error(message, status)
  end

  def render_error(message, status = :bad_request)
    render json: { error: message }, status: status
  end

  def ai_agent_params
    params.require(:ai_agent).permit(
      :name,
      :description,
      :template_id,
      :system_prompts,
      :welcoming_message,
      :routing_conditions,
      :control_flow_rules,
      :llm_model,
      :history_limit,
      :context_limit,
      :message_await,
      :message_limit,
      :timezone,
      selected_labels: %i[label_id label_condition]
    )
  end
end
