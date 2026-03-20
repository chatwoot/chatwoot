class Api::V1::Accounts::Contacts::GroupJoinRequestsController < Api::V1::Accounts::Contacts::BaseController
  def index
    authorize @contact, :show?
    requests = channel.group_join_requests(@contact.identifier)
    render json: { payload: requests }
  rescue Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def handle
    authorize @contact, :update?
    channel.handle_group_join_requests(@contact.identifier, handle_params[:participants], handle_params[:request_action])
    remove_handled_requests(handle_params[:participants])
    head :ok
  rescue Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def handle_params
    params.permit(:request_action, participants: [])
  end

  def channel
    @channel ||= @contact.group_channel
  end

  def remove_handled_requests(participants)
    return if participants.blank?

    current_requests = @contact.additional_attributes&.dig('pending_join_requests') || []
    updated_requests = current_requests.reject { |r| participants.include?(r['jid']) }
    new_attrs = (@contact.additional_attributes || {}).merge('pending_join_requests' => updated_requests)
    @contact.update!(additional_attributes: new_attrs)
  end
end
