class Api::V1::Accounts::Captain::MessageReportsController < Api::V1::Accounts::BaseController
  before_action :ensure_cloud_installation
  before_action :set_message

  def create
    @message_report = @message.message_reports.create!(
      user: Current.user,
      report_reason: permitted_params[:report_reason],
      description: permitted_params[:description]
    )
  end

  private

  def ensure_cloud_installation
    render json: { error: 'Not available' }, status: :not_found unless ChatwootApp.chatwoot_cloud?
  end

  def set_message
    @message = Current.account.messages.find(permitted_params[:message_id])
  end

  def permitted_params
    params.permit(:message_id, :report_reason, :description)
  end
end
