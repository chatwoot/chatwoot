class HookJob < ApplicationJob
  queue_as :medium

  def perform(hook, event_name, event_data = {})
    Rails.logger.info "HookJob: Processing event #{event_name} for hook #{hook.id} (app: #{hook.app_id})"
    Rails.logger.info "HookJob: Event data: #{event_data.inspect}"
    
    return if hook.disabled?
    Rails.logger.info "HookJob: Hook is enabled, proceeding with processing"

    case hook.app_id
    when 'slack'
      process_slack_integration(hook, event_name, event_data)
    when 'dialogflow'
      process_dialogflow_integration(hook, event_name, event_data)
    when 'google_translate'
      google_translate_integration(hook, event_name, event_data)
    when 'hubspot'
      process_hubspot_integration(hook, event_name, event_data)
    else
      Rails.logger.warn "HookJob: No processor found for app_id: #{hook.app_id}"
    end
  rescue StandardError => e
    Rails.logger.error "HookJob Error: #{e.message}"
    Rails.logger.error "HookJob Error Backtrace: #{e.backtrace.join("\n")}"
  end

  private

  def process_slack_integration(hook, event_name, event_data)
    return unless ['message.created'].include?(event_name)

    message = event_data[:message]
    if message.attachments.blank?
      ::SendOnSlackJob.perform_later(message, hook)
    else
      ::SendOnSlackJob.set(wait: 2.seconds).perform_later(message, hook)
    end
  end

  def process_dialogflow_integration(hook, event_name, event_data)
    return unless ['message.created', 'message.updated'].include?(event_name)

    Integrations::Dialogflow::ProcessorService.new(event_name: event_name, hook: hook, event_data: event_data).perform
  end

  def google_translate_integration(hook, event_name, event_data)
    return unless ['message.created'].include?(event_name)

    message = event_data[:message]
    Integrations::GoogleTranslate::DetectLanguageService.new(hook: hook, message: message).perform
  end

  def process_hubspot_integration(hook, event_name, event_data)
    Rails.logger.info "HookJob: Processing HubSpot integration for event: #{event_name}"
    Rails.logger.info "HookJob: HubSpot event data: #{event_data.inspect}"
    
    return unless ['message.created', 'contact.created', 'contact.updated'].include?(event_name)
    Rails.logger.info "HookJob: Event type is valid for HubSpot"

    # Convert record to appropriate event data structure
    event_data = case event_name
                 when 'message.created'
                   { message: event_data[:message] || event_data[:record] }
                 when 'contact.created', 'contact.updated'
                   { contact: event_data[:message] || event_data[:record] }
                 end

    Rails.logger.info "HookJob: Processed event data: #{event_data.inspect}"
    Integrations::Hubspot::ProcessorService.new(event_name: event_name, hook: hook, event_data: event_data).perform
  end
end
