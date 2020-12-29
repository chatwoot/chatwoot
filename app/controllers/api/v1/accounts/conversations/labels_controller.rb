class Api::V1::Accounts::Conversations::LabelsController < Api::V1::Accounts::Conversations::BaseController
  include LabelHelper

  private

  def model
    @model ||= @conversation
  end

  def permitted_params
    params.permit(:conversation_id, :labels)
  end
end
