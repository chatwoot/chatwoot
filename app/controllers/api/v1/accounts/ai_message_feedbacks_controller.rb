class Api::V1::Accounts::AiMessageFeedbacksController < Api::V1::Accounts::BaseController
  before_action :fetch_message

  def create
    # Authorize based on agent's ability to update the message
    authorize @message, :update?

    # Build the feedback hash
    feedback = {
      rating: feedback_params[:rating],
      feedback_text: feedback_params[:feedback_text],
      agent_id: Current.user.id,
      created_at: Time.current.utc.iso8601
    }

    # Merge with existing attributes and save
    @message.content_attributes = @message.content_attributes.merge('ai_feedback' => feedback)
    @message.save!

    render json: @message
  end

  def update
    authorize @message, :update?

    # Ensure the feedback exists and the agent is authorized to update it
    existing_feedback = @message.content_attributes['ai_feedback']
    return head :not_found unless existing_feedback
    return head :unauthorized if existing_feedback['agent_id'] != Current.user.id && !Current.user.administrator?

    # Merge the new params into the existing feedback
    updated_feedback = existing_feedback.merge(
      'rating' => feedback_params[:rating],
      'feedback_text' => feedback_params[:feedback_text],
      'updated_at' => Time.current.utc.iso8601
    )

    @message.content_attributes = @message.content_attributes.merge('ai_feedback' => updated_feedback)
    @message.save!

    render json: @message
  end

  def destroy
    authorize @message, :update?

    # Ensure the feedback exists and the agent is authorized to delete it
    existing_feedback = @message.content_attributes['ai_feedback']
    return head :not_found unless existing_feedback
    return head :unauthorized if existing_feedback['agent_id'] != Current.user.id && !Current.user.administrator?

    # Remove the feedback key and save
    updated_attributes = @message.content_attributes.except('ai_feedback')
    @message.content_attributes = updated_attributes
    @message.save!

    head :ok
  end

  private

  def fetch_message
    message_id = params[:id] || params[:message_id]
    @message = Current.account.messages.find(message_id)
  end

  def feedback_params
    params.require(:ai_feedback).permit(:rating, :feedback_text)
  end

  def permitted_params
    params.permit(:message_id, ai_feedback: [:rating, :feedback_text])
  end
end 