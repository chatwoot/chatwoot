class Api::V1::Accounts::Contacts::GroupInvitesController < Api::V1::Accounts::Contacts::BaseController
  include GroupChannelResolver

  def show
    authorize @contact, :show?
    code = channel.group_invite_code(@contact.identifier)
    render json: invite_response(code)
  rescue Whatsapp::Session::Errors::Error => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def revoke
    authorize @contact, :update?
    code = channel.revoke_group_invite(@contact.identifier)
    render json: invite_response(code)
  rescue Whatsapp::Session::Errors::Error => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def invite_response(code)
    { invite_code: code, invite_url: "https://chat.whatsapp.com/#{code}" }
  end
end
