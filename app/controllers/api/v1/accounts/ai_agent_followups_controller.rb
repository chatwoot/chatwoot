class Api::V1::Accounts::AiAgentFollowupsController < Api::V1::Accounts::BaseController
  before_action :set_ai_agent, only: %i[update]

  def update
    followup_params = params.fetch(:_json, []).map { |f| followup_permitted_params(f) }

    ActiveRecord::Base.transaction do
      remove_deleted_followups(followup_params)
      upsert_followups(followup_params)
    end

    render json: @ai_agent.ai_agent_followups, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    handle_error(e.message, status: :unprocessable_entity)
  end

  private

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

  def followup_permitted_params(followup)
    followup.permit(:id, :prompts, :delay, :send_as_exact_message, :handoff_to_agent_after_sending)
  end
end
