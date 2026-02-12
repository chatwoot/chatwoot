# frozen_string_literal: true

# Tool for checking available Calendly time slots
# Used by AI agent to help customers find suitable meeting times
#
# Example usage in agent:
#   chat.with_tools([CalendlyCheckAvailabilityTool])
#   response = chat.ask("What times are available for a demo this week?")
#
class CalendlyCheckAvailabilityTool < BaseTool
  description 'Check available time slots for scheduling a Calendly meeting. ' \
              'Use when the customer asks about availability or wants to know when they can book.'

  param :event_type_name, type: :string,
                          desc: 'Name or partial name of the event type. Uses default if not specified.',
                          required: false
  param :date, type: :string,
               desc: 'Start date to check availability (ISO 8601, e.g., "2025-05-20"). Defaults to today.',
               required: false

  def execute(event_type_name: nil, date: nil)
    validate_context!

    if playground_mode?
      return success_response(
        message: '[Playground] Would check Calendly availability',
        event_type_name: event_type_name || 'default',
        date: date || 'next 7 days'
      )
    end

    validate_calendly_enabled!
    event_type_uri = resolve_event_type_uri(event_type_name)
    slots = fetch_available_slots(event_type_uri, date)

    success_response(
      available_slots: slots,
      message: slots.any? ? 'Here are the available time slots.' : 'No available time slots found for the requested period.'
    )
  rescue StandardError => e
    error_response("Failed to check availability: #{e.message}")
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

  def fetch_available_slots(event_type_uri, date)
    start_time = resolve_start_time(date)
    end_time = start_time + 7.days

    slots = api_client.list_available_times(event_type_uri, start_time: start_time, end_time: end_time)
    slots.map { |slot| { start_time: slot['start_time'], status: slot['status'] } }
  end

  # Calendly requires start_time to be in the future
  def resolve_start_time(date)
    return Time.current if date.blank?

    [Time.zone.parse(date), Time.current].max
  end

  def calendly_hook
    @calendly_hook ||= current_account.hooks.find_by(app_id: 'calendly')
  end

  def api_client
    @api_client ||= Integrations::Calendly::ApiClient.new(calendly_hook)
  end
end
