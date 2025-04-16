class HookJob < ApplicationJob
  queue_as :medium

  def perform(hook, event_name, event_data = {})
    return if hook.disabled?

    case hook.app_id
    when 'slack'
      process_slack_integration(hook, event_name, event_data)
    when 'dialogflow'
      process_dialogflow_integration(hook, event_name, event_data)
    when 'google_translate'
      google_translate_integration(hook, event_name, event_data)
    when 'leadsquared'
      process_leadsquared_integration(hook, event_name, event_data)
    end
  rescue StandardError => e
    Rails.logger.error e
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

  def process_leadsquared_integration(hook, event_name, event_data)
    # Process the event with the processor service
    processor = Crm::Leadsquared::ProcessorService.new(hook)

    case event_name
    when 'contact.created'
      processor.handle_contact_created(event_data[:contact])
    when 'contact.updated'
      processor.handle_contact_updated(event_data[:contact])
    when 'conversation.created'
      processor.handle_conversation_created(event_data[:conversation])
    when 'conversation.resolved'
      processor.handle_conversation_resolved(event_data[:conversation])
    end
  end
end
