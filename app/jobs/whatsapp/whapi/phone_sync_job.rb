class Whatsapp::Whapi::PhoneSyncJob < ApplicationJob
  queue_as :low
  retry_on StandardError, wait: 1.minute, attempts: 5

  def perform(channel_id)
    channel = Channel::Whatsapp.find_by(id: channel_id)
    return unless channel&.provider == 'whapi'

    service = Whatsapp::Partner::WhapiPartnerService.new
    result = service.sync_channel_phone_number(channel_token: channel.provider_config_object.whapi_channel_token)
    
    if result[:success]
      channel.provider_config_object.update_phone_number(result[:phone_number])
      channel.provider_config_object.update_user_status(result[:status])
      
      # Update webhook URL with phone number
      begin
        new_webhook_url = service.update_webhook_with_phone_number(
          channel_token: channel.provider_config_object.whapi_channel_token,
          phone_number: result[:phone_number]
        )
        channel.provider_config_object.update_webhook_url(new_webhook_url)
        Rails.logger.info "PhoneSyncJob: Phone number synced and webhook updated for channel #{channel_id}"
      rescue StandardError => e
        Rails.logger.warn "PhoneSyncJob: Webhook update failed for channel #{channel_id}: #{e.message}"
        # Don't fail the job for webhook update errors as phone sync succeeded
      end
    else
      Rails.logger.warn "PhoneSyncJob: Phone sync failed for channel #{channel_id}: #{result[:error]}"
    end
  end
end
