class Api::V1::Accounts::Conversations::GroupController < Api::V1::Accounts::Conversations::BaseController
  before_action :ensure_group_conversation
  before_action :ensure_session_group_admin, only: [:update]

  def show; end

  def update
    response = provider_service.update_group(
      group_id: @conversation.group_source_id,
      subject: group_params[:subject],
      description: group_params[:description],
      picture_url: group_picture_url
    )

    if response.success?
      update_local_group_attributes
      render :show
    else
      render json: { error: provider_error(response, 'Provider failed to update group') }, status: :unprocessable_entity
    end
  end

  def sync
    result = Whatsapp::Unoapi::GroupParticipantsSyncService.new(inbox: @conversation.inbox, conversation: @conversation).perform
    return render :show if result == :ok

    render json: { error: result }, status: :unprocessable_entity
  end

  private

  def ensure_group_conversation
    render json: { error: 'Conversation is not a group' }, status: :not_found unless @conversation.group?
  end

  def ensure_session_group_admin
    render json: { error: 'Connected session must be a group admin' }, status: :forbidden unless @conversation.group_session_admin?
  end

  def provider_service
    @provider_service ||= @conversation.inbox.channel.provider_service
  end

  def group_params
    params.permit(:subject, :description, :picture_url)
  end

  def update_local_group_attributes
    attrs = {
      group_title: group_params[:subject].presence,
      group_description: group_params[:description].presence
    }.compact

    if group_picture_url.present?
      @conversation.additional_attributes ||= {}
      @conversation.additional_attributes['group_picture'] = group_picture_url
      Avatar::AvatarFromUrlJob.perform_later(@conversation.contact, group_picture_url)
    end

    @conversation.update!(attrs)
  end

  def group_picture_url
    return if group_params[:picture_url].blank?
    return group_params[:picture_url] unless group_params[:picture_url].start_with?('/')

    "#{ENV.fetch('FRONTEND_URL', request.base_url)}#{group_params[:picture_url]}"
  end

  def provider_error(response, fallback)
    response.parsed_response.try(:[], 'error') || fallback
  end
end
