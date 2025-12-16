class Api::V1::Accounts::Captain::EditorController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def process_event
    result = Captain::EditorService.new(
      account: Current.account,
      event: params[:event]
    ).perform

    if result.nil?
      render json: { message: nil }
    elsif result[:error]
      render json: { error: result[:error] }, status: :unprocessable_entity
    else
      render json: { message: result[:message] }
    end
  end

  private

  def check_authorization
    authorize(:'captain/editor')
  end
end
