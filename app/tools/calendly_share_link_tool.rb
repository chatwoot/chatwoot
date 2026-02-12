# frozen_string_literal: true

# Tool for sharing a Calendly scheduling link with the customer
# Creates a single-use link for a specific event type
#
# Example usage in agent:
#   chat.with_tools([CalendlyShareLinkTool])
#   response = chat.ask("Share a scheduling link for a 30-minute demo")
#
class CalendlyShareLinkTool < BaseTool
  description 'Create and share a Calendly scheduling link with the customer. ' \
              'Use when the customer wants to book a meeting, demo, or appointment. ' \
              'The link will be single-use. Include the booking_url in your reply to the customer.'

  param :event_type_name, type: :string,
                          desc: 'Name or partial name of the event type (e.g., "30-Minute Demo"). ' \
                                'If not specified, uses the default event type.',
                          required: false

  def execute(event_type_name: nil)
    validate_context!

    if playground_mode?
      return success_response(
        message: '[Playground] Would create Calendly scheduling link',
        event_type_name: event_type_name || 'default'
      )
    end

    validate_calendly_enabled!
    event_type_uri = resolve_event_type_uri(event_type_name)
    link = api_client.create_scheduling_link(event_type_uri)
    booking_url = prefill_booking_url(link['booking_url'])

    success_response(
      booking_url: booking_url,
      message: 'Scheduling link created. Include the booking_url in your message to the customer.'
    )
  rescue StandardError => e
    error_response("Failed to create scheduling link: #{e.message}")
  end

  private

  def validate_calendly_enabled!
    raise ArgumentError, 'Calendly is not connected for this account.' unless calendly_hook
  end

  def resolve_event_type_uri(name)
    default_uri = calendly_hook.settings['default_event_type_uri']
    return default_uri if name.blank? && default_uri.present?

    event_types = api_client.list_event_types
    return event_types.first['uri'] if name.blank? && event_types.any?

    match = event_types.find { |et| et['name'].downcase.include?(name.downcase) }
    raise ArgumentError, "No event type matching '#{name}' found." unless match

    match['uri']
  end

  def prefill_booking_url(url)
    params = contact_prefill_params
    return url if params.empty?

    separator = url.include?('?') ? '&' : '?'
    "#{url}#{separator}#{URI.encode_www_form(params)}"
  end

  def contact_prefill_params
    contact = current_conversation&.contact
    return {} unless contact

    params = {}
    params[:name] = contact.name if contact.name.present?
    params[:email] = contact.email if contact.email.present?
    params
  end

  def calendly_hook
    @calendly_hook ||= current_account.hooks.find_by(app_id: 'calendly')
  end

  def api_client
    @api_client ||= Integrations::Calendly::ApiClient.new(calendly_hook)
  end
end
