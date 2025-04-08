class Api::V1::Accounts::AiAgentsController < Api::V1::Accounts::BaseController
  before_action :set_ai_agent, only: %i[show update destroy avatar update_followups]

  def index
    @ai_agents = Current.account.ai_agents.select(:id, :account_id, :name, :description)
    render json: @ai_agents
  end

  def show
    render json: serialize_ai_agent
  end

  def create
    ai_agent_template = find_template

    Rails.logger.debug { "AI Agent Template: #{ai_agent_template.inspect}" }

    chat_flow_id = load_chat_flow(ai_agent_template)
    return unless chat_flow_id

    @ai_agent = build_ai_agent(ai_agent_template, chat_flow_id)

    if @ai_agent.save
      render json: @ai_agent, status: :created
    else
      render json: @ai_agent.errors, status: :unprocessable_entity
    end
  end

  def update
    if @ai_agent.update(ai_agent_params)
      update_selected_labels if params[:ai_agent].key?(:selected_labels)

      render json: @ai_agent.as_json(include: :ai_agent_selected_labels)
    else
      render json: @ai_agent.errors, status: :unprocessable_entity
    end
  end

  def avatar
    @ai_agent.avatar.purge if @ai_agent.avatar.attached?
    render json: @ai_agent
  end

  def destroy
    @ai_agent.destroy
    head :no_content
  end

  def update_followups
    followup_params = params.require(:_json).map { |f| followup_permitted_params(f) }

    ActiveRecord::Base.transaction do
      remove_deleted_followups(followup_params)
      upsert_followups(followup_params)
    end

    render json: @ai_agent.ai_agent_followups, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def ai_agent_templates
    agent_templates = AiAgentTemplate.select(:id, :name, :template)
    render json: agent_templates, status: :ok
  end

  private

  def serialize_ai_agent
    json = @ai_agent.as_json(
      only: ai_agent_fields,
      include: ai_agent_includes
    )

    rename_keys(json)
  end

  def ai_agent_fields
    [
      :id, :uid, :name, :description, :system_prompts, :welcoming_message,
      :routing_conditions, :control_flow_rules, :model_name,
      :history_limit, :context_limit, :message_await, :message_limit,
      :timezone, :created_at, :updated_at, :account_id, :chat_flow_id
    ]
  end

  def ai_agent_includes
    {
      ai_agent_selected_labels: {
        only: [:id, :label_id, :label_conditions],
        include: {
          label: {
            only: [:id, :name]
          }
        }
      },
      ai_agent_followups: {
        only: [:id, :prompts, :delay, :send_as_exact_message, :handoff_to_agent_after_sending]
      }
    }
  end

  def rename_keys(json)
    {
      'ai_agent_selected_labels' => 'selected_labels',
      'ai_agent_followups' => 'followups'
    }.each do |original, renamed|
      json[renamed] = json.delete(original) if json.key?(original)
    end
    json
  end

  def find_template
    AiAgentTemplate.find_by(id: params[:ai_agent][:template_id]).tap do |template|
      render json: { error: 'AI Agent Template not found' }, status: :not_found unless template
    end
  end

  def load_chat_flow(template)
    flowise_service = AiAgents::FlowiseService.new
    response = flowise_service.load_chat_flow(
      name: ai_agent_params[:name],
      flow_data: template.template
    )
    response['id']
  rescue StandardError => e
    Rails.logger.error("Failed to load chat flow: #{e.message}")
    render json: { error: "Failed to load chat flow: #{e.message}" }, status: :bad_gateway
    nil
  end

  def build_ai_agent(template, chat_flow_id)
    Current.account.ai_agents.new(
      ai_agent_params.merge(
        system_prompts: template.system_prompt,
        welcoming_message: template.welcoming_message,
        chat_flow_id: chat_flow_id
      )
    )
  end

  def remove_deleted_followups(received_followups)
    received_ids = received_followups.filter_map { |f| f[:id] }.compact

    if received_ids.empty?
      @ai_agent.ai_agent_followups.destroy_all
    else
      @ai_agent.ai_agent_followups.where.not(id: received_ids).destroy_all
    end
  end

  def upsert_followups(followups)
    followups.each do |followup_data|
      if followup_data[:id].nil?
        @ai_agent.ai_agent_followups.create!(followup_data.except(:id))
      else
        existing_followup = @ai_agent.ai_agent_followups.find_by(id: followup_data[:id])
        raise ActiveRecord::RecordNotFound, "ID #{followup_data[:id]} not found." unless existing_followup

        existing_followup.update!(followup_data.except(:id))
      end
    end
  end

  def update_followup(followup_data)
    followup = @ai_agent.ai_agent_followups.find(followup_data[:id])
    followup.update!(followup_data)
  end

  def create_followup(followup_data)
    @ai_agent.ai_agent_followups.create!(followup_data)
  end

  def set_ai_agent
    @ai_agent = Current.account.ai_agents.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'AI Agent not found' }, status: :not_found
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

  def followup_permitted_params(followup)
    followup.permit(:id, :prompts, :delay, :send_as_exact_message, :handoff_to_agent_after_sending)
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
