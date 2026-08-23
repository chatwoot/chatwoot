class Api::V1::Accounts::Integrations::CalendarController < Api::V1::Accounts::Integrations::BaseController
  include GoogleCalendar::IntegrationHelper

  wrap_parameters format: []

  before_action :check_admin_authorization?, only: [:oauth, :destroy, :update_calendars]
  before_action :ensure_google_configured, only: [:oauth]
  before_action :fetch_connection, only: [:calendars, :update_calendars, :destroy]
  before_action :fetch_connection_for_events, only: [:events, :create_event, :update_event, :destroy_event, :lock_event, :unlock_event]

  def oauth
    state = generate_google_calendar_token(Current.account.id)
    render json: { url: Integrations::GoogleCalendar::Oauth.authorize_url(state) }
  end

  def index
    items = Current.account.calendar_connections.active.includes(:connected_by).order(created_at: :desc).map do |connection|
      ensure_google_profile_name!(connection)
      {
        id: connection.id,
        provider: connection.provider,
        email: connection.email,
        name: connection.profile_name,
        connected_by: connection.connected_by && {
          id: connection.connected_by.id,
          name: connection.connected_by.available_name.presence || connection.connected_by.name
        },
        created_at: connection.created_at,
        enabled_calendars_count: connection.enabled_calendars.count
      }
    end

    render json: {
      payload: items,
      configured: Integrations::GoogleCalendar::Oauth.configured?
    }
  end

  def calendars
    sync_google_calendars!
    render json: { payload: serialize_connection_calendars }
  rescue StandardError => e
    Rails.logger.error("Google Calendar list failed: #{e.message}")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update_calendars
    Array(calendars_params).each do |item|
      record = @connection.connection_calendars.find_or_initialize_by(external_id: item[:external_id])
      record.account = Current.account
      record.summary = item[:summary] if item[:summary].present?
      record.is_enabled = ActiveModel::Type::Boolean.new.cast(item[:is_enabled])
      record.hour_start = item[:hour_start] unless item[:hour_start].nil?
      record.hour_end = item[:hour_end] unless item[:hour_end].nil?
      record.save!
    end
    render json: { payload: serialize_connection_calendars(all: true) }
  end

  def events
    if permitted_params[:contact_id].present?
      items = event_service.list_for_contact(
        contact_id: permitted_params[:contact_id],
        calendar_id: permitted_params[:calendar_id],
        time_min: permitted_params[:time_min],
        time_max: permitted_params[:time_max]
      )
    else
      items = event_service.list(
        calendar_id: permitted_params[:calendar_id],
        time_min: time_min,
        time_max: time_max
      )
    end
    render json: { payload: items }
  rescue StandardError => e
    render_calendar_error(e)
  end

  def create_event
    item = event_service.create(event_params)
    render json: { payload: item }
  rescue StandardError => e
    render_calendar_error(e)
  end

  def update_event
    item = event_service.update(params[:event_id], event_params)
    render json: { payload: item }
  rescue StandardError => e
    render_calendar_error(e)
  end

  def destroy_event
    item = event_service.destroy(params[:event_id], event_params)
    if item
      render json: { payload: item }
    else
      head :ok
    end
  rescue StandardError => e
    render_calendar_error(e)
  end

  def lock_event
    lock = event_lock
    result = permitted_params[:heartbeat].present? ? lock.heartbeat(Current.user) : lock.acquire(Current.user)
    return render json: { payload: result[:holder] } if result[:ok]

    render json: {
      payload: result[:holder],
      error: I18n.t('integration_apps.calendars.locked', name: result.dig(:holder, 'name'))
    }, status: :locked
  end

  def unlock_event
    event_lock.release(Current.user)
    head :ok
  end

  def destroy
    @connection.update!(is_active: false)
    head :ok
  end

  private

  def ensure_google_configured
    return if Integrations::GoogleCalendar::Oauth.configured?

    render json: { error: 'Google Calendar is not configured' }, status: :unprocessable_entity
  end

  def ensure_google_profile_name!(connection)
    return if connection.display_name.present?

    name = google_profile_name_for(connection)
    name ||= connection.connected_by&.available_name.presence
    connection.update!(display_name: name) if name.present?
  rescue StandardError => e
    Rails.logger.warn("Calendar profile name sync failed: #{e.message}")
  end

  def google_profile_name_for(connection)
    token = Integrations::GoogleCalendar::TokenService.new(connection: connection).access_token
    Integrations::GoogleCalendar::Oauth.fetch_profile(token)[:name].presence || name_from_primary_calendar(connection)
  end

  def name_from_primary_calendar(connection)
    summary = connection.connection_calendars.find_by(is_primary: true)&.summary.to_s.strip
    return if summary.blank? || summary.include?('@')

    summary
  end

  def fetch_connection
    @connection = Current.account.calendar_connections.active.find(params[:id])
  end

  def fetch_connection_for_events
    @connection = Current.account.calendar_connections.active.find(permitted_params[:connection_id])
  end

  def event_service
    Integrations::GoogleCalendar::EventService.new(account: Current.account, user: Current.user, connection: @connection)
  end

  def event_lock
    Integrations::GoogleCalendar::EventLock.new(account_id: Current.account.id, event_id: params[:event_id])
  end

  def sync_google_calendars!
    token = Integrations::GoogleCalendar::TokenService.new(connection: @connection).access_token
    Integrations::GoogleCalendar::Client.new(token).list_calendars.each do |calendar|
      record = @connection.connection_calendars.find_or_initialize_by(external_id: calendar['id'])
      record.account = Current.account
      record.summary = calendar['summary'].to_s
      record.is_primary = calendar['primary'] == true
      record.save!
    end
  end

  def serialize_connection_calendars(all: list_all_calendars?)
    scope = all ? @connection.connection_calendars : @connection.enabled_calendars
    scope.order(is_enabled: :desc, is_primary: :desc, summary: :asc).map do |calendar|
      {
        id: calendar.external_id,
        summary: calendar.summary,
        primary: calendar.is_primary,
        enabled: calendar.is_enabled,
        hour_start: calendar.hour_start,
        hour_end: calendar.hour_end
      }
    end
  end

  def list_all_calendars?
    administrator? && ActiveModel::Type::Boolean.new.cast(params[:all])
  end

  def administrator?
    Current.account_user&.administrator?
  end

  def time_min
    permitted_params[:time_min].presence || Time.current.beginning_of_week(:monday).utc.iso8601
  end

  def time_max
    permitted_params[:time_max].presence || Time.current.end_of_week(:monday).utc.iso8601
  end

  def render_calendar_error(error)
    Rails.logger.error("Google Calendar error: #{error.class} #{error.message}")
    case error
    when Integrations::GoogleCalendar::Client::PreconditionFailed
      render json: { error: I18n.t('integration_apps.calendars.stale') }, status: :precondition_failed
    when Integrations::GoogleCalendar::EventService::EventLocked
      render json: { error: I18n.t('integration_apps.calendars.locked', name: error.holder_name) }, status: :locked
    when Integrations::GoogleCalendar::EventService::SlotBusy
      render json: {
        error: slot_busy_message(error),
        code: 'slot_busy',
        conflict: error.conflict
      }, status: :unprocessable_entity
    when Integrations::GoogleCalendar::EventService::CalendarNotEnabled
      render json: { error: I18n.t('integration_apps.calendars.not_enabled') }, status: :unprocessable_entity
    when Integrations::GoogleCalendar::EventService::InvalidRange
      render json: { error: I18n.t('integration_apps.calendars.invalid_range') }, status: :unprocessable_entity
    when Integrations::GoogleCalendar::EventService::MissingDeleteNote
      render json: { error: I18n.t('integration_apps.calendars.delete_note_required') }, status: :unprocessable_entity
    else
      render json: { error: error.message }, status: :unprocessable_entity
    end
  end

  def slot_busy_message(error)
    conflict = (error.conflict || {}).with_indifferent_access
    case conflict[:reason]
    when 'in_progress'
      I18n.t('integration_apps.calendars.slot_in_progress')
    when 'overlap'
      args = {
        title: conflict[:summary].presence || I18n.t('integration_apps.calendars.untitled'),
        name: conflict.dig(:created_by, :name),
        start: clock_label(conflict[:start]),
        end: clock_label(conflict[:end])
      }
      if args[:name].present?
        I18n.t('integration_apps.calendars.slot_overlap', **args)
      else
        I18n.t('integration_apps.calendars.slot_overlap_unknown', **args)
      end
    else
      I18n.t('integration_apps.calendars.slot_busy')
    end
  end

  def clock_label(value)
    return '' if value.blank?

    Time.iso8601(value.to_s).in_time_zone(Integrations::GoogleCalendar::Client::TIMEZONE).strftime('%H:%M')
  rescue ArgumentError
    value.to_s
  end

  def permitted_params
    params.permit(
      :id, :connection_id, :calendar_id, :event_id, :time_min, :time_max, :heartbeat,
      :summary, :start, :end, :etag, :contact_id, :conversation_id, :include_meet, :send_to_contact,
      :attendee_email, :all, :note, :idempotency_key
    )
  end

  def event_params
    permitted_params
  end

  def calendars_params
    params.permit(calendars: [:external_id, :summary, :is_enabled, :hour_start, :hour_end])[:calendars]
  end
end
