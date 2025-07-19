class SetupWhatsappUnofficialDeviceJob < ApplicationJob
  queue_as :default

  def perform(channel_id)
    channel = Channel::WhatsappUnofficial.find_by(id: channel_id)
    return unless channel

    # Skip if token already exists (device already set up)
    if channel.token.present?
      Rails.logger.info "Device already set up for channel #{channel_id}, phone: #{channel.phone_number}"
      return
    end

    Rails.logger.info "Setting up WAHA device for channel #{channel_id}, phone: #{channel.phone_number}"
    
    channel.send(:set_webhook_url)
    
    channel.send(:create_device_with_retry)
    
    Rails.logger.info "Finished setting up WAHA device for channel #{channel_id}"
  rescue StandardError => e
    Rails.logger.error "SetupWhatsappUnofficialDeviceJob failed for channel #{channel_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end
