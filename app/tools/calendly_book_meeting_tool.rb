# frozen_string_literal: true

# Tool for booking a Calendly meeting — combines availability check and link creation
# Gives the AI agent a single action to handle "I want to book a meeting" requests
#
# Example usage in agent:
#   chat.with_tools([CalendlyBookMeetingTool])
#   response = chat.ask("Book a 30-minute demo for the customer next Tuesday")
#
class CalendlyBookMeetingTool < BaseTool
  description 'Book a Calendly meeting for the customer. ' \
              'Checks available time slots and creates a single-use scheduling link. ' \
              'Use when a customer wants to schedule, book, or set up a meeting. ' \
              'Include the booking_url and available times in your reply so the customer can pick a slot.'

  param :event_type_name, type: :string,
                          desc: 'Name or partial name of the event type (e.g., "30-Minute Demo"). Uses default if not specified.',
                          required: false
  param :date, type: :string,
               desc: 'Preferred date to check availability (ISO 8601, e.g., "2025-05-20"). Defaults to today.',
               required: false
  param :days_ahead, type: :integer,
                     desc: 'Number of days ahead to show availability (1-7). Defaults to 7.',
                     required: false

  def execute(event_type_name: nil, date: nil, days_ahead: nil)
    validate_context!
    return playground_booking(event_type_name, date, days_ahead) if playground_mode?

    validate_calendly_enabled!
    event_type_uri = resolve_event_type_uri(event_type_name)
    slots = fetch_available_slots(event_type_uri, date, days_ahead || 7)
    link = api_client.create_scheduling_link(event_type_uri)

    success_response(
      booking_url: link['booking_url'],
      available_slots: slots,
      message: build_message(slots)
    )
  rescue StandardError => e
    error_response("Failed to book meeting: #{e.message}")
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

  def fetch_available_slots(event_type_uri, date, days)
    start_time = resolve_start_time(date)
    end_time = start_time + days.clamp(1, 7).days

    slots = api_client.list_available_times(event_type_uri, start_time: start_time, end_time: end_time)
    slots.first(20).map do |slot|
      { start_time: slot['start_time'], status: slot['status'] }
    end
  end

  # Calendly requires start_time to be in the future
  def resolve_start_time(date)
    return Time.current if date.blank?

    [Time.zone.parse(date), Time.current].max
  end

  def playground_booking(event_type_name, date, days_ahead)
    success_response(
      message: '[Playground] Would create a Calendly booking',
      event_type_name: event_type_name || 'default',
      date: date || 'today',
      days_ahead: days_ahead || 7
    )
  end

  def build_message(slots)
    if slots.any?
      "Found #{slots.length} available slot(s). Share the booking_url with the customer so they can pick a time and complete the booking."
    else
      'No available slots found for the requested period, but here is the booking_url. The customer can browse other dates.'
    end
  end

  def calendly_hook
    @calendly_hook ||= current_account.hooks.find_by(app_id: 'calendly')
  end

  def api_client
    @api_client ||= Integrations::Calendly::ApiClient.new(calendly_hook)
  end
end
