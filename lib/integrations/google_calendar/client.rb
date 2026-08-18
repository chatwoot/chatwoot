class Integrations::GoogleCalendar::Client
  BASE_URL = 'https://www.googleapis.com/calendar/v3'
  TIMEOUT = 30
  TIMEZONE = 'America/Guayaquil'

  class Error < StandardError
    attr_reader :code, :body

    def initialize(message, code: nil, body: nil)
      super(message)
      @code = code
      @body = body
    end
  end

  class PreconditionFailed < Error; end

  def initialize(access_token)
    @access_token = access_token
  end

  def list_calendars
    calendars = []
    page_token = nil

    loop do
      params = { minAccessRole: 'writer' }
      params[:pageToken] = page_token if page_token.present?
      data = get('/users/me/calendarList', params)
      calendars.concat(Array(data['items']))
      page_token = data['nextPageToken']
      break if page_token.blank?
    end

    calendars
  end

  def list_events(calendar_id:, time_min:, time_max:)
    events = []
    page_token = nil

    loop do
      params = {
        timeMin: time_min,
        timeMax: time_max,
        singleEvents: true,
        orderBy: 'startTime',
        maxResults: 250
      }
      params[:pageToken] = page_token if page_token.present?
      data = get(events_path(calendar_id), params)
      events.concat(Array(data['items']))
      page_token = data['nextPageToken']
      break if page_token.blank?
    end

    events
  end

  def get_event(calendar_id:, event_id:)
    get(event_path(calendar_id, event_id))
  end

  def create_event(calendar_id:, summary:, start_at:, end_at:, description: nil, extended_properties: {}, include_meet: false, attendee_email: nil)
    body = event_body(summary:, start_at:, end_at:, description:, extended_properties:, include_meet:, attendee_email:)
    params = {}
    params[:conferenceDataVersion] = 1 if include_meet
    params[:sendUpdates] = 'all' if attendee_email.present?
    post(events_path(calendar_id), body, params)
  end

  def update_event(calendar_id:, event_id:, etag:, summary:, start_at:, end_at:, description: nil, extended_properties: {}, include_meet: false, attendee_email: nil)
    body = event_body(summary:, start_at:, end_at:, description:, extended_properties:, include_meet:, attendee_email:)
    params = {}
    params[:conferenceDataVersion] = 1 if include_meet
    params[:sendUpdates] = 'all' if attendee_email.present?
    headers = etag.present? ? { 'If-Match' => etag } : {}
    patch(event_path(calendar_id, event_id), body, params, headers)
  end

  def delete_event(calendar_id:, event_id:, etag: nil)
    headers = etag.present? ? { 'If-Match' => etag } : {}
    delete(event_path(calendar_id, event_id), headers)
  end

  private

  def event_body(summary:, start_at:, end_at:, description:, extended_properties:, include_meet:, attendee_email: nil)
    body = {
      summary: summary,
      start: { dateTime: start_at.iso8601, timeZone: TIMEZONE },
      end: { dateTime: end_at.iso8601, timeZone: TIMEZONE }
    }
    body[:description] = description if description.present?
    body[:extendedProperties] = { private: extended_properties } if extended_properties.present?
    body[:attendees] = [{ email: attendee_email }] if attendee_email.present?
    if include_meet
      body[:conferenceData] = {
        createRequest: {
          requestId: "inboxhub-#{SecureRandom.uuid}",
          conferenceSolutionKey: { type: 'hangoutsMeet' }
        }
      }
    end
    body
  end

  def events_path(calendar_id)
    "/calendars/#{CGI.escape(calendar_id)}/events"
  end

  def event_path(calendar_id, event_id)
    "#{events_path(calendar_id)}/#{CGI.escape(event_id)}"
  end

  def get(path, params = {})
    handle HTTParty.get("#{BASE_URL}#{path}", request_options(query: params))
  end

  def post(path, body, params = {})
    handle HTTParty.post("#{BASE_URL}#{path}", request_options(query: params, body: body.to_json))
  end

  def patch(path, body, params = {}, extra_headers = {})
    handle HTTParty.patch("#{BASE_URL}#{path}", request_options(query: params, body: body.to_json, extra_headers: extra_headers))
  end

  def delete(path, extra_headers = {})
    handle HTTParty.delete("#{BASE_URL}#{path}", request_options(extra_headers: extra_headers)), allow_empty: true
  end

  def request_options(query: {}, body: nil, extra_headers: {})
    options = {
      headers: {
        'Authorization' => "Bearer #{@access_token}",
        'Accept' => 'application/json',
        'Content-Type' => 'application/json'
      }.merge(extra_headers),
      timeout: TIMEOUT
    }
    options[:query] = query if query.present?
    options[:body] = body if body
    options
  end

  def handle(response, allow_empty: false)
    return {} if allow_empty && [204, 404, 410].include?(response.code)
    return response.parsed_response if response.success?

    message = "Google Calendar API failed: #{response.code} #{response.body}"
    raise PreconditionFailed.new(message, code: response.code, body: response.body) if response.code == 412
    raise Error.new(message, code: response.code, body: response.body)
  end
end
