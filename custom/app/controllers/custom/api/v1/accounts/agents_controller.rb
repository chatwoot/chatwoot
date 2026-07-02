# frozen_string_literal: true

module Custom::Api::V1::Accounts::AgentsController
  def create
    return super unless autonomia_product_invitations_enabled?

    invitation = Autonomia::ProductInvitations::AgentInviter.new(
      account: Current.account,
      inviter: current_user,
      agent_params: autonomia_agent_params.to_h.merge('custom_role_id' => custom_role_id_param)
    ).perform

    render json: {
      pending_invitation: true,
      email: invitation.email,
      name: invitation.name,
      role: invitation.role,
      invitation_url: invitation.invitation_url,
      email_delivery_failed: invitation.email_delivery_failed,
      manual_share_required: invitation.manual_share_required,
      email_delivery_error: invitation.email_delivery_error
    }, status: :created
  rescue Autonomia::ProductInvitations::AgentInviter::Error => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def autonomia_product_invitations_enabled?
    ActiveModel::Type::Boolean.new.cast(
      ENV.fetch('AUTONOMIA_PRODUCT_INVITATIONS_ENABLED', ENV.fetch('AUTONOMIA_SSO_ENABLED', false))
    )
  end

  def custom_role_id_param
    params.dig(:agent, :custom_role_id).presence || params[:custom_role_id]
  end

  def autonomia_agent_params
    params.require(:agent).permit(
      :email,
      :name,
      :role,
      :availability,
      :auto_offline,
      :create_whatsapp_api_inbox,
      :whatsapp_api_phone,
      inbox_ids: []
    )
  end
end
