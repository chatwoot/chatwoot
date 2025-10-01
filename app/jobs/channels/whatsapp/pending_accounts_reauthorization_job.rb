class Channels::Whatsapp::PendingAccountsReauthorizationJob < ApplicationJob
  queue_as :low

  def perform
    find_pending_whatsapp_channels.each do |channel|
      Rails.logger.info "Processing pending WhatsApp channel: #{channel.id}"
      channel.prompt_reauthorization!
      Rails.logger.info "Successfully prompted reauthorization for channel: #{channel.id}"
    rescue StandardError => e
      Rails.logger.error "Failed to prompt reauthorization for channel #{channel.id}: #{e.message}"
    end
  end

  private

  def find_pending_whatsapp_channels
    Channel::Whatsapp.joins(:inbox).where(inboxes: { account_id: account_ids }).select do |channel|
      pending_channel?(channel)
    end
  end

  def pending_channel?(channel)
    health_data = Whatsapp::HealthService.new(channel).fetch_health_status
    return false unless health_data

    health_data[:platform_type] == 'NOT_APPLICABLE' ||
      health_data.dig(:throughput, 'level') == 'NOT_APPLICABLE' ||
      health_data[:messaging_limit_tier].nil?
  rescue StandardError => e
    Rails.logger.error "Failed to fetch health data for channel #{channel.id}: #{e.message}"
    false
  end

  def account_ids
    Account.pluck(:id)
  end
end
