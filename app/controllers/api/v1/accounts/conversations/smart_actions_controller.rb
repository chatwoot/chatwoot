class Api::V1::Accounts::Conversations::SmartActionsController < Api::V1::Accounts::Conversations::BaseController
  def index
    @smart_actions = @conversation.smart_actions
  end

  def create
    builder = SmartActionBuilder.new(@conversation, params)
    @smart_action = builder.perform

    render json: {
      success: @smart_action.present?,
      message: builder.errors.present? ? builder.errors.join(', ') : 'Successfully created'
    }
  end
end
