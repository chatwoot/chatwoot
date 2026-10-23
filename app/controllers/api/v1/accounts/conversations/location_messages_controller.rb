class Api::V1::Accounts::Conversations::LocationMessagesController < Api::V1::Accounts::Conversations::BaseController
  before_action :ensure_whatsapp_cloud_inbox

  rescue_from Whatsapp::LocationMessageService::Error do |error|
    render_could_not_create_error(error.message)
  end

  def create
    @message = Whatsapp::LocationMessageService.new(
      conversation: @conversation, sender: Current.user, params: params.permit(:location_id, :latitude, :longitude)
    ).perform
    render 'api/v1/accounts/conversations/messages/create'
  end

  private

  def ensure_whatsapp_cloud_inbox
    channel = @conversation.inbox.channel
    return if channel.is_a?(Channel::Whatsapp) && channel.provider == 'whatsapp_cloud'

    render_could_not_create_error(I18n.t('errors.whatsapp.location_message.cloud_inbox_required'))
  end
end
