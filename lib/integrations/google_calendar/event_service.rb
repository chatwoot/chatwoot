class Integrations::GoogleCalendar::EventService
  TIMEZONE = Integrations::GoogleCalendar::Client::TIMEZONE

  class SlotBusy < StandardError
    attr_reader :conflict

    def initialize(reason: 'overlap', summary: nil, start: nil, end_at: nil, created_by: nil)
      @conflict = {
        reason: reason,
        summary: summary,
        start: start,
        end: end_at,
        created_by: created_by
      }.compact
      super('slot_busy')
    end
  end
  class MissingDeleteNote < StandardError; end
  class CalendarNotEnabled < StandardError; end
  class InvalidRange < StandardError; end
  class EventLocked < StandardError
    attr_reader :holder_name

    def initialize(holder_name)
      @holder_name = holder_name
      super("locked:#{holder_name}")
    end
  end

  def initialize(account:, user:, connection:)
    @account = account
    @user = user
    @connection = connection
  end

  def list(calendar_id:, time_min:, time_max:)
    ensure_calendar_enabled!(calendar_id)
    google_events = client.list_events(calendar_id: calendar_id, time_min: time_min, time_max: time_max)
    google_ids = google_events.map { |event| event['id'] }
    locals = local_records_by_google_id(google_ids)
    google_events.each { |event| sync_google_drift!(event, locals[event['id']]) }
    live = google_events.map { |event| serialize(event, locals[event['id']], calendar_id) }
    live + discarded_in_range(calendar_id, time_min, time_max, google_ids)
  end

  def self.conversation_payloads(conversation)
    conversation.account.calendar_events
                .where(conversation_id: conversation.id)
                .includes(:created_by, :updated_by, :deleted_by, :contact, :conversation, :calendar_connection, activities: :user)
                .order(Arel.sql('deleted_at NULLS FIRST'), start_at: :asc)
                .map { |record| payload_from_record(record) }
  end

  def self.contact_payloads(account, contact_id, calendar_id: nil, time_min: nil, time_max: nil)
    scope = account.calendar_events
                   .kept
                   .where(contact_id: contact_id)
                   .includes(:created_by, :updated_by, :deleted_by, :contact, :conversation, :calendar_connection, activities: :user)
    scope = scope.where(external_calendar_id: calendar_id) if calendar_id.present?
    if time_min.present? && time_max.present?
      scope = scope.where('start_at < ? AND end_at > ?', Time.iso8601(time_max), Time.iso8601(time_min))
    end
    scope.order(start_at: :asc).map { |record| payload_from_record(record) }
  end

  def list_for_contact(contact_id:, calendar_id: nil, time_min: nil, time_max: nil)
    self.class.contact_payloads(
      account,
      contact_id,
      calendar_id: calendar_id,
      time_min: time_min,
      time_max: time_max
    )
  end
  alias list_by_contact list_for_contact

  def self.payload_from_record(record)
    {
      id: record.google_event_id,
      summary: record.summary.presence || I18n.t('integration_apps.calendars.untitled'),
      start: record.start_at&.iso8601,
      end: record.end_at&.iso8601,
      all_day: false,
      html_link: record.html_link,
      etag: record.etag,
      deleted: record.discarded?,
      deleted_note: deleted_note_for(record),
      connection_id: record.calendar_connection_id,
      calendar_id: record.external_calendar_id,
      created_by: record.created_by && { id: record.created_by.id, name: record.created_by.name },
      updated_by: record.updated_by && { id: record.updated_by.id, name: record.updated_by.name },
      deleted_by: record.deleted_by && { id: record.deleted_by.id, name: record.deleted_by.name },
      contact: record.contact && { id: record.contact.id, name: record.contact.name, email: record.contact.email },
      conversation: record.conversation && { id: record.conversation.display_id },
      activities: serialize_activities(record)
    }
  end

  def self.serialize_activities(record)
    return [] if record.blank?

    record.activities.sort_by(&:created_at).reverse.first(20).map do |activity|
      {
        id: activity.id,
        action: activity.action,
        created_at: activity.created_at.iso8601,
        user: activity.user && { id: activity.user.id, name: activity.user.name },
        details: activity.details
      }
    end
  end

  def self.deleted_note_for(record)
    return if record.blank?

    record.activities.sort_by(&:created_at).reverse.find { |item| item.action == 'deleted' }&.details&.[]('note').presence
  end

  def create(params)
    if (existing = find_by_idempotency_key(params[:idempotency_key]))
      return self.class.payload_from_record(existing)
    end

    calendar_id = params[:calendar_id]
    ensure_calendar_enabled!(calendar_id)
    start_at, end_at = parse_range(params)
    with_booking_lock(calendar_id) do
      if (existing = find_by_idempotency_key(params[:idempotency_key]))
        return self.class.payload_from_record(existing)
      end

      ensure_slot_available!(calendar_id, start_at, end_at)
      contact = find_contact(params[:contact_id])
      conversation = find_conversation(params[:conversation_id])
      google_event = client.create_event(
        calendar_id: calendar_id,
        summary: params[:summary].presence || I18n.t('integration_apps.calendars.default_title'),
        start_at: start_at,
        end_at: end_at,
        description: human_description(contact, conversation),
        extended_properties: private_properties(contact, conversation),
        include_meet: ActiveModel::Type::Boolean.new.cast(params[:include_meet]),
        attendee_email: params[:attendee_email].presence || contact&.email
      )
      record = upsert_local!(
        google_event, calendar_id, contact, conversation,
        creating: true, idempotency_key: params[:idempotency_key]
      )
      notify_conversation!(conversation, :event_created, record)
      send_to_contact!(conversation, record, google_event) if send_to_contact?(params, conversation)
      serialize(google_event, record, calendar_id)
    end
  end

  def update(event_id, params)
    calendar_id = params[:calendar_id]
    ensure_calendar_enabled!(calendar_id)
    ensure_lock!(event_id)
    start_at, end_at = parse_range(params)
    record = connection.calendar_events.find_by(google_event_id: event_id)
    with_booking_lock(calendar_id) do
      if slot_changed?(record, start_at, end_at)
        ensure_slot_available!(calendar_id, start_at, end_at, except_event_id: event_id)
      end
      contact = find_contact(params[:contact_id])
      conversation = find_conversation(params[:conversation_id])
      google_event = client.update_event(
        calendar_id: calendar_id,
        event_id: event_id,
        etag: params[:etag],
        summary: params[:summary].presence || I18n.t('integration_apps.calendars.default_title'),
        start_at: start_at,
        end_at: end_at,
        description: human_description(contact, conversation),
        extended_properties: private_properties(contact, conversation),
        include_meet: ActiveModel::Type::Boolean.new.cast(params[:include_meet]),
        attendee_email: params[:attendee_email].presence || contact&.email
      )
      record = upsert_local!(google_event, calendar_id, contact, conversation, creating: false)
      notify_conversation!(conversation, :event_updated, record)
      send_to_contact!(conversation, record, google_event) if send_to_contact?(params, conversation)
      serialize(google_event, record, calendar_id)
    end
  end

  def destroy(event_id, params)
    calendar_id = params[:calendar_id]
    ensure_calendar_enabled!(calendar_id)
    ensure_lock!(event_id)
    record = connection.calendar_events.find_by(google_event_id: event_id)
    note = params[:note].to_s.strip
    raise MissingDeleteNote if record && !record.discarded? && note.blank?

    client.delete_event(calendar_id: calendar_id, event_id: event_id, etag: params[:etag])
    if record && !record.discarded?
      attrs = { deleted_at: Time.current }
      attrs[:deleted_by] = actor_user if actor_user
      attrs[:updated_by] = actor_user if actor_user
      record.update!(attrs)
      record_activity!(record, 'deleted', activity_details_from(record).merge('note' => note))
      notify_conversation!(record.conversation, :event_deleted, record)
    end
    Integrations::GoogleCalendar::EventLock.new(account_id: account.id, event_id: event_id).release(user)
    return unless record

    record.reload
    self.class.payload_from_record(record)
  end

  private

  attr_reader :account, :user, :connection

  def client
    @client ||= begin
      token = Integrations::GoogleCalendar::TokenService.new(connection: connection).access_token
      Integrations::GoogleCalendar::Client.new(token)
    end
  end

  def ensure_calendar_enabled!(calendar_id)
    raise CalendarNotEnabled unless connection.calendar_enabled?(calendar_id)
  end

  def ensure_lock!(event_id)
    result = Integrations::GoogleCalendar::EventLock.new(account_id: account.id, event_id: event_id).acquire(user)
    raise EventLocked, result.dig(:holder, 'name') unless result[:ok]
  end

  def with_booking_lock(calendar_id)
    lock = Integrations::GoogleCalendar::BookingLock.new(account_id: account.id, calendar_id: calendar_id)
    raise SlotBusy.new(reason: 'in_progress') unless lock.acquire

    yield
  ensure
    lock&.release
  end

  def ensure_slot_available!(calendar_id, start_at, end_at, except_event_id: nil)
    local = overlapping_local(calendar_id, start_at, end_at, except_event_id)
    raise_slot_busy_from_local(local) if local

    google_event = overlapping_google(calendar_id, start_at, end_at, except_event_id)
    raise_slot_busy_from_google(google_event) if google_event
  end

  def slot_changed?(record, start_at, end_at)
    return true if record.blank?

    times_differ?(record.start_at, start_at) || times_differ?(record.end_at, end_at)
  end

  def overlapping_local(calendar_id, start_at, end_at, except_event_id)
    scope = connection.calendar_events.kept
                      .where(external_calendar_id: calendar_id)
                      .where('start_at < ? AND end_at > ?', end_at, start_at)
                      .includes(:created_by)
    scope = scope.where.not(google_event_id: except_event_id) if except_event_id.present?
    scope.order(:start_at).first
  end

  def overlapping_google(calendar_id, start_at, end_at, except_event_id)
    client.list_events(
      calendar_id: calendar_id,
      time_min: start_at.iso8601,
      time_max: end_at.iso8601
    ).find { |event| google_event_overlaps?(event, start_at, end_at, except_event_id) }
  end

  def google_event_overlaps?(event, start_at, end_at, except_event_id)
    return false if except_event_id.present? && event['id'] == except_event_id
    return false if event['status'] == 'cancelled'
    return false if event['transparency'] == 'transparent'

    other_start = parse_google_time(event['start'])
    other_end = parse_google_time(event['end'])
    return false if other_start.blank? || other_end.blank?

    start_at < other_end && end_at > other_start
  end

  def raise_slot_busy_from_local(record)
    raise SlotBusy.new(
      reason: 'overlap',
      summary: record.summary,
      start: record.start_at&.iso8601,
      end_at: record.end_at&.iso8601,
      created_by: record.created_by && { name: record.created_by.name }
    )
  end

  def raise_slot_busy_from_google(event)
    local = connection.calendar_events.find_by(google_event_id: event['id'])
    raise SlotBusy.new(
      reason: 'overlap',
      summary: event['summary'].presence || local&.summary,
      start: parse_google_time(event['start'])&.iso8601,
      end_at: parse_google_time(event['end'])&.iso8601,
      created_by: local&.created_by && { name: local.created_by.name }
    )
  end

  def parse_range(params)
    zone = Time.find_zone!(TIMEZONE)
    start_at = zone.parse(params[:start].to_s)
    end_at = params[:end].present? ? zone.parse(params[:end].to_s) : start_at + 30.minutes
    raise InvalidRange if start_at.blank? || end_at <= start_at

    [start_at, end_at]
  end

  def find_contact(contact_id)
    return if contact_id.blank?

    account.contacts.find(contact_id)
  end

  def find_conversation(display_id)
    return if display_id.blank?

    account.conversations.find_by!(display_id: display_id)
  end

  def private_properties(contact, conversation)
    {
      'inboxhub_account_id' => account.id.to_s,
      'inboxhub_user_id' => user.id.to_s,
      'inboxhub_contact_id' => contact&.id.to_s,
      'inboxhub_conversation_id' => conversation&.id.to_s
    }.compact_blank
  end

  def human_description(contact, conversation)
    parts = ['Cita InboxHub', user.name]
    parts << "Conversación ##{conversation.display_id}" if conversation
    parts << contact.name if contact
    parts.join(' · ')
  end

  def upsert_local!(google_event, calendar_id, contact, conversation, creating:, idempotency_key: nil)
    record = connection.calendar_events.find_or_initialize_by(google_event_id: google_event['id'])
    was_new = record.new_record?
    before = snapshot(record) unless was_new
    attrs = {
      account: account,
      external_calendar_id: calendar_id,
      etag: google_event['etag'],
      summary: google_event['summary'],
      start_at: parse_google_time(google_event['start']),
      end_at: parse_google_time(google_event['end']),
      html_link: google_event['htmlLink'],
      contact: contact,
      conversation: conversation
    }
    attrs[:updated_by] = actor_user if actor_user
    attrs[:idempotency_key] = idempotency_key if idempotency_key.present? && record.idempotency_key.blank?
    record.assign_attributes(attrs)
    record.created_by ||= actor_user if actor_user && (creating || was_new)
    record.save!
    if was_new || creating
      record_activity!(record, 'created', activity_details_from(record))
    else
      details = diff_snapshots(before, snapshot(record))
      record_activity!(record, 'updated', details) if details.any?
    end
    record
  end

  def find_by_idempotency_key(key)
    return if key.blank?

    account.calendar_events.kept.find_by(idempotency_key: key)
  end

  # created_by/updated_by FKs point at users — AgentBot must not be assigned.
  def actor_user
    user.is_a?(User) ? user : nil
  end

  def discarded_in_range(calendar_id, time_min, time_max, google_ids)
    scope = connection.calendar_events
                      .where.not(deleted_at: nil)
                      .where(external_calendar_id: calendar_id)
                      .where(start_at: Time.iso8601(time_min)...Time.iso8601(time_max))
                      .includes(:created_by, :updated_by, :deleted_by, :contact, :conversation, activities: :user)
    scope = scope.where.not(google_event_id: google_ids) if google_ids.any?
    scope.map { |record| self.class.payload_from_record(record) }
  end

  def local_records_by_google_id(ids)
    connection.calendar_events
              .where(google_event_id: ids)
              .includes(:created_by, :updated_by, :deleted_by, :contact, :conversation, activities: :user)
              .index_by(&:google_event_id)
  end

  def sync_google_drift!(google_event, record)
    return if record.blank? || record.discarded?
    return if google_event.dig('start', 'dateTime').blank?

    google_start = parse_google_time(google_event['start'])
    google_end = parse_google_time(google_event['end'])
    after = {
      summary: google_event['summary'].presence || record.summary,
      start_at: google_start,
      end_at: google_end
    }
    details = diff_snapshots(snapshot(record), after)
    return if details.empty?

    record.update!(
      start_at: google_start,
      end_at: google_end,
      summary: after[:summary],
      etag: google_event['etag'],
      html_link: google_event['htmlLink']
    )
    record_activity!(record, 'moved_in_google', details)
  end

  def record_activity!(record, action, details = {})
    actor = action == 'moved_in_google' ? nil : actor_user
    record.activities.create!(account: account, user: actor, action: action, details: details)
  end

  def snapshot(record)
    {
      summary: record.summary,
      start_at: record.start_at,
      end_at: record.end_at
    }
  end

  def diff_snapshots(before, after)
    details = {}
    details['summary'] = [before[:summary], after[:summary]] if before[:summary] != after[:summary]
    if times_differ?(before[:start_at], after[:start_at])
      details['start_at'] = [before[:start_at]&.iso8601, after[:start_at]&.iso8601]
    end
    if times_differ?(before[:end_at], after[:end_at])
      details['end_at'] = [before[:end_at]&.iso8601, after[:end_at]&.iso8601]
    end
    details
  end

  def times_differ?(left, right)
    return false if left.blank? && right.blank?
    return true if left.blank? || right.blank?

    left.to_i != right.to_i
  end

  def activity_details_from(record)
    {
      'summary' => record.summary,
      'start_at' => record.start_at&.iso8601,
      'end_at' => record.end_at&.iso8601
    }
  end

  def parse_google_time(payload)
    return if payload.blank?

    value = payload['dateTime'].presence || payload['date']
    Time.iso8601(value)
  rescue ArgumentError
    Time.zone.parse(value)
  end

  def serialize(event, record, calendar_id)
    start_at = event.dig('start', 'dateTime').presence || event.dig('start', 'date')
    end_at = event.dig('end', 'dateTime').presence || event.dig('end', 'date')
    {
      id: event['id'],
      summary: event['summary'].presence || I18n.t('integration_apps.calendars.untitled'),
      start: start_at,
      end: end_at,
      all_day: event.dig('start', 'dateTime').blank?,
      html_link: event['htmlLink'],
      location: event['location'],
      status: event['status'],
      etag: event['etag'],
      description: event['description'],
      meet_link: meet_link(event),
      connection_id: connection.id,
      calendar_id: calendar_id,
      deleted: record&.discarded? || false,
      deleted_note: self.class.deleted_note_for(record),
      created_by: user_payload(record&.created_by),
      updated_by: user_payload(record&.updated_by),
      deleted_by: user_payload(record&.deleted_by),
      contact: contact_payload(record&.contact),
      conversation: conversation_payload(record&.conversation),
      activities: self.class.serialize_activities(record)
    }
  end

  def meet_link(event)
    Array(event.dig('conferenceData', 'entryPoints')).find { |entry| entry['entryPointType'] == 'video' }&.fetch('uri', nil)
  end

  def user_payload(person)
    return if person.blank?

    { id: person.id, name: person.name }
  end

  def contact_payload(contact)
    return if contact.blank?

    { id: contact.id, name: contact.name, email: contact.email }
  end

  def conversation_payload(conversation)
    return if conversation.blank?

    { id: conversation.display_id }
  end

  def notify_conversation!(conversation, action_type, record)
    return if conversation.blank?

    Integrations::GoogleCalendar::ActivityMessageService.new(
      conversation: conversation,
      action_type: action_type,
      user: user,
      event_data: { summary: record&.summary }
    ).perform
  end

  def send_to_contact?(params, conversation)
    conversation.present? && ActiveModel::Type::Boolean.new.cast(params[:send_to_contact])
  end

  def send_to_contact!(conversation, record, google_event)
    zone = Time.find_zone!(TIMEZONE)
    start_label = record.start_at&.in_time_zone(zone)&.strftime('%Y-%m-%d %H:%M')
    meet = meet_link(google_event)
    content = I18n.t('integration_apps.calendars.customer_message', title: record.summary, start_at: start_label)
    content = "#{content}\n#{record.html_link}" if record.html_link.present?
    content = "#{content}\n#{meet}" if meet.present?
    conversation.messages.create!(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :outgoing,
      content: content,
      sender: user
    )
  end
end
