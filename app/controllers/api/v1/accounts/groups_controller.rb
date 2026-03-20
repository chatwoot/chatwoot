class Api::V1::Accounts::GroupsController < Api::V1::Accounts::BaseController
  def create
    inbox = Current.account.inboxes.find_by(id: group_params[:inbox_id])
    return render json: { error: 'Access Denied' }, status: :forbidden unless inbox_accessible?(inbox)

    result = Groups::CreateService.new(
      inbox: inbox,
      subject: group_params[:subject],
      participants: Array(group_params[:participants])
    ).perform

    render json: result
  rescue Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def group_params
    params.permit(:inbox_id, :subject, participants: [])
  end

  def inbox_accessible?(inbox)
    inbox.present? && Current.user.assigned_inboxes.exists?(id: inbox.id) && inbox.channel.try(:allow_group_creation?)
  end
end
