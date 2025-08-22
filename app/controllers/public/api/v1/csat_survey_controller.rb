class Public::Api::V1::CsatSurveyController < PublicController
  before_action :set_conversation
  before_action :set_message

  def show; end

  def update # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    if check_csat_locked
      expiry_hours = @conversation.inbox.csat_expiry_hours || 336
      if expiry_hours < 24
        expiry_text = expiry_hours == 1 ? '1 hour' : "#{expiry_hours} hours"
      else
        days = expiry_hours / 24
        remaining_hours = expiry_hours % 24
        if remaining_hours.zero?
          expiry_text = days == 1 ? '1 day' : "#{days} days" # rubocop:disable Metrics/BlockNesting
        else
          day_text = days == 1 ? '1 day' : "#{days} days" # rubocop:disable Metrics/BlockNesting
          hour_text = remaining_hours == 1 ? '1 hour' : "#{remaining_hours} hours" # rubocop:disable Metrics/BlockNesting
          expiry_text = "#{day_text} and #{hour_text}"
        end
      end
      render json: { error: "You cannot update the CSAT survey after #{expiry_text}" }, status: :unprocessable_entity and return
    end

    @message.update!(message_update_params[:message])
  end

  private

  def set_conversation
    return if params[:id].blank?

    @conversation = Conversation.find_by!(uuid: params[:id])
  end

  def set_message
    # Find the latest active CSAT message (not marked as ignored)
    @message = @conversation.messages
                            .where(content_type: 'input_csat')
                            .where("additional_attributes->>'ignore_automation_rules' IS NULL")
                            .order(created_at: :desc)
                            .first!
  end

  def message_update_params
    params.permit(message: [{ submitted_values: [:name, :title, :value, { csat_survey_response: [:feedback_message, :rating] }] }])
  end

  def check_csat_locked
    # Use inbox-specific expiry if configured, otherwise default to 336 hours (14 days)
    expiry_hours = @conversation.inbox.csat_expiry_hours || 336
    (Time.zone.now - @message.created_at) > expiry_hours.hours
  end
end
