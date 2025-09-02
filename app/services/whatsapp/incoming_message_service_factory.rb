# frozen_string_literal: true

# Factory for creating the appropriate incoming message service based on channel provider
# This follows the same pattern as Billing::ProviderFactory to maintain consistency
class Whatsapp::IncomingMessageServiceFactory
  # Creates and returns the appropriate incoming message service instance
  #
  # @param channel [Channel::Whatsapp] The WhatsApp channel
  # @param params [Hash] The webhook parameters
  # @param correlation_id [String] The correlation ID for tracking
  # @return [Whatsapp::IncomingMessageBaseService] The appropriate service instance
  def self.create(channel:, params:, correlation_id:)
    provider = channel.provider || 'default'
    service_class = service_class_for(provider)
    service_class.new(
      inbox: channel.inbox,
      params: params.merge('correlation_id' => correlation_id)
    )
  rescue StandardError => e
    Rails.logger.error "Failed to create incoming message service for #{provider}: #{e.message}"
    # Fallback to default service
    Whatsapp::IncomingMessageService.new(
      inbox: channel.inbox,
      params: params.merge('correlation_id' => correlation_id)
    )
  end

  # Maps provider names to their corresponding service classes
  #
  # @param provider [String] The provider name
  # @return [Class] The service class for the provider
  def self.service_class_for(provider)
    case provider
    when 'whatsapp_cloud'
      Whatsapp::IncomingMessageWhatsappCloudService
    when 'whapi'
      Whatsapp::IncomingMessageWhapiService
    else
      Whatsapp::IncomingMessageService
    end
  end

  private_class_method :service_class_for
end