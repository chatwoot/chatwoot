class Integrations::Hubspot::ProcessorService
  ALLOWED_EVENT_NAMES = %w[message.created contact.created contact.updated].freeze

  pattr_initialize [:event_name!, :hook!, :event_data!]

  def perform
    Rails.logger.info "HubSpot Integration: Processing event #{event_name}"
    Rails.logger.info "HubSpot Integration: Event data: #{event_data.inspect}"
    Rails.logger.info "HubSpot Integration: Hook details - id: #{hook.id}, account_id: #{hook.account_id}"
    
    return unless valid_event_name?
    Rails.logger.info "HubSpot Integration: Event name is valid"

    case event_name
    when 'message.created'
      return unless message.present?
      Rails.logger.info "HubSpot Integration: Starting sync for message #{message.id}"
      Rails.logger.info "HubSpot Integration: Message details - content: #{message.content}, conversation_id: #{message.conversation_id}"
      sync_message_to_hubspot
    when 'contact.created', 'contact.updated'
      return unless contact.present?
      Rails.logger.info "HubSpot Integration: Starting sync for contact #{contact.id}"
      Rails.logger.info "HubSpot Integration: Contact details - email: #{contact.email}, name: #{contact.name}"
      sync_contact_to_hubspot
    end
  rescue StandardError => e
    Rails.logger.error "HubSpot Integration Error: #{e.message}"
    Rails.logger.error "HubSpot Integration Error Backtrace: #{e.backtrace.join("\n")}"
    nil
  end

  private

  def sync_message_to_hubspot
    Rails.logger.info "HubSpot Integration: Creating service with access token"
    hubspot_service = Integrations::Hubspot::InboxSyncService.new(hook.access_token, message.conversation.inbox)
    Rails.logger.info "HubSpot Integration: Starting message sync"
    result = hubspot_service.sync_message(message)
    Rails.logger.info "HubSpot Integration: Sync result: #{result.inspect}"
    result
  end

  def sync_contact_to_hubspot
    Rails.logger.info "HubSpot Integration: Creating service with access token"
    hubspot_service = Integrations::Hubspot::ContactsSyncService.new(hook.access_token)
    Rails.logger.info "HubSpot Integration: Starting contact sync"
    result = hubspot_service.sync_contact(contact)
    Rails.logger.info "HubSpot Integration: Sync result: #{result.inspect}"
    result
  end

  def message
    @message ||= event_data[:message]
  end

  def contact
    @contact ||= event_data[:contact]
  end

  def valid_event_name?
    ALLOWED_EVENT_NAMES.include?(event_name)
  end
end 