class Api::V1::Accounts::AiAgentsController < Api::V1::Accounts::BaseController
  before_action :set_ai_agent, only: %i[show update destroy]

  def index
    @ai_agents = Current.account.ai_agents.select(:id, :account_id, :name)
    render json: @ai_agents
  end

  def show
    render json: @ai_agent.as_json(
      only: [
        :id, :uid, :name, :system_prompts, :welcoming_message,
        :routing_conditions, :control_flow_rules, :model_name,
        :history_limit, :context_limit, :message_await, :message_limit,
        :timezone, :created_at, :updated_at, :account_id
      ],
      include: {
        ai_agent_selected_labels: {
          only: [:id, :label_id, :label_conditions],
          include: {
            label: {
              only: [:id, :name]
            }
          }
        }
      }
    ).transform_keys { |key| key == 'ai_agent_selected_labels' ? 'selected_labels' : key }
  end

  def create
    ai_agent_template = AiAgentTemplate.find(params[:ai_agent][:template_id])

    unless ai_agent_template
      render json: { error: 'AI Agent Template not found' }, status: :not_found
      return
    end

    @ai_agent = Current.account.ai_agents.new(
      ai_agent_params.merge(
        system_prompts: ai_agent_template.system_prompt,
        welcoming_message: ai_agent_template.welcoming_message
      )
    )

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

  private

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

  def ai_agent_params
    params.require(:ai_agent).permit(
      :name,
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
