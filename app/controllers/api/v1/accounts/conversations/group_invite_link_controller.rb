class Api::V1::Accounts::Conversations::GroupInviteLinkController < Api::V1::Accounts::Conversations::BaseController
  before_action :ensure_group_conversation
  before_action :ensure_session_group_admin, only: [:reset]

  def show
    response = @conversation.inbox.channel.provider_service.group_invite_link(@conversation.group_source_id)
    if response.success?
      @conversation.update!(group_invite_link: parsed_invite_link(response))
      render :show
    else
      render json: { error: provider_error(response, 'Provider failed to fetch invite link') }, status: :unprocessable_entity
    end
  end

  def reset
    response = @conversation.inbox.channel.provider_service.reset_group_invite_link(@conversation.group_source_id)
    if response.success?
      @conversation.update!(group_invite_link: parsed_invite_link(response))
      render :show
    else
      render json: { error: provider_error(response, 'Provider failed to reset invite link') }, status: :unprocessable_entity
    end
  end

  private

  def ensure_group_conversation
    render json: { error: 'Conversation is not a group' }, status: :not_found unless @conversation.group?
  end

  def ensure_session_group_admin
    render json: { error: 'Connected session must be a group admin' }, status: :forbidden unless @conversation.group_session_admin?
  end

  def parsed_invite_link(response)
    payload = response.parsed_response.with_indifferent_access
    payload[:invite_link] || payload[:inviteLink] || payload[:link] || payload.dig(:group, :invite_link) || payload.dig(:group, :inviteLink)
  end

  def provider_error(response, fallback)
    response.parsed_response.try(:[], 'error') || fallback
  end
end
