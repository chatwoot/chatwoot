module Api::V1::Accounts::Concerns::InboxDisplayNameManagement
  extend ActiveSupport::Concern

  def apply_display_name
    return render json: { error: I18n.t('whatsapp.display_name.unsupported_channel') }, status: :unprocessable_entity unless whatsapp_cloud_channel?

    Whatsapp::DisplayNameService.new(@inbox.channel).perform(display_name: params.permit(:display_name)[:display_name])
    render json: { registration_submitted: true }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
