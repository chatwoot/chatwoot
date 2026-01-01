# frozen_string_literal: true

module Enterprise::Api::V1::Accounts::ConversationsController
  extend ActiveSupport::Concern

  def inbox_assistant
    assistant = @conversation.inbox.aloo_assistant

    if assistant&.active?
      render json: { assistant: { id: assistant.id, name: assistant.name } }
    else
      render json: { assistant: nil }
    end
  end

  def reporting_events
    @reporting_events = @conversation.reporting_events.order(created_at: :asc)
  end

  def permitted_update_params
    super.merge(params.permit(:sla_policy_id))
  end
end
