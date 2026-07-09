require 'net/http'

class Api::V1::Accounts::Crm::MeetingsController < Api::V1::Accounts::Crm::BaseController
  include Crm::IdempotentRequests

  before_action :ensure_calendar_meetings_enabled
  before_action :fetch_meeting, only: [:show, :sync, :update, :destroy, :record_outcome, :summarize]

  RESULTS_PER_PAGE = 50
  MAX_RESULTS_PER_PAGE = 100
  ISO8601_OFFSET_REGEX = /(?:Z|[+-]\d{2}:?\d{2})\z/.freeze

  def index
    authorize ::Crm::FollowUp, :index?
    meetings = filtered_meetings.order(:starts_at, :id)
    render json: {
      payload: meetings.page(params[:page] || 1).per(per_page).map { |meeting| serialize(meeting) },
      meta: { count: meetings.count }
    }
  end

  def show
    render json: { payload: serialize(@meeting) }
  end

  def sync
    # 2-way sync (S7): reconcile time + cancellation + RSVP from the provider calendar.
    Crm::Meetings::SyncService.new(meeting: @meeting, force: params[:force].present?).perform
    # Re-fetch through visible_meetings so the serializer keeps the eager-loads
    # (avoids N+1) and reflects the freshly-synced status/time/RSVP. The meeting may
    # have just been canceled by the sync, so fall back to a plain reload.
    synced = visible_meetings.find_by(id: @meeting.id) || @meeting.reload
    render json: { payload: serialize(synced) }, status: :ok
  end

  def create
    with_idempotency do
      authorize ::Crm::FollowUp, :create?
      authorize card, :update?

      meeting = Crm::Meetings::Creator.new(
        account: Current.account,
        card: card,
        inbox: inbox,
        scheduled_by: Current.user,
        params: meeting_params
      ).perform

      render json: { payload: serialize(meeting) }, status: :created
    end
  rescue ArgumentError, ActiveRecord::RecordInvalid
    render json: { error: 'Invalid meeting request' }, status: :unprocessable_entity
  rescue StandardError => e
    if calendar_provider_error?(e)
      render json: { error: 'Calendar provider unavailable' }, status: :bad_gateway
    else
      Rails.logger.error("CRM meeting create failed: #{e.class.name}")
      render json: { error: 'Internal server error' }, status: :internal_server_error
    end
  end

  def update
    authorize @meeting.card, :update?

    Crm::Meetings::RescheduleService.new(meeting: @meeting, params: reschedule_params).perform

    render json: { payload: serialize(visible_meetings.find(@meeting.id)) }, status: :ok
  rescue ArgumentError
    render json: { error: 'Invalid reschedule request' }, status: :unprocessable_entity
  rescue StandardError => e
    if calendar_provider_error?(e)
      render json: { error: 'Calendar provider unavailable' }, status: :bad_gateway
    else
      Rails.logger.error("CRM meeting reschedule failed: #{e.class.name}")
      render json: { error: 'Internal server error' }, status: :internal_server_error
    end
  end

  def destroy
    authorize @meeting.card, :update?

    Crm::Meetings::CancelService.new(meeting: @meeting).perform

    render json: { payload: serialize(visible_meetings.find(@meeting.id)) }, status: :ok
  rescue StandardError => e
    if calendar_provider_error?(e)
      render json: { error: 'Calendar provider unavailable' }, status: :bad_gateway
    else
      Rails.logger.error("CRM meeting cancel failed: #{e.class.name}")
      render json: { error: 'Internal server error' }, status: :internal_server_error
    end
  end

  def record_outcome
    authorize @meeting.card, :update?

    Crm::Meetings::RecordOutcomeService.new(
      meeting: @meeting,
      outcome: outcome_params[:outcome],
      notes: outcome_params[:notes]
    ).perform

    render json: { payload: serialize(visible_meetings.find(@meeting.id)) }, status: :ok
  rescue ArgumentError
    render json: { error: 'Invalid outcome request' }, status: :unprocessable_entity
  end

  # AI: suggest the best free times for a (not-yet-created) meeting. Collection
  # route — the card/inbox come from the body, like #create. Fail-safe: if AI is
  # off/unconfigured the service still returns the free-slot fallback (reason=nil).
  def suggest_times
    authorize card, :update?

    suggestions = Crm::Ai::SuggestMeetingTimeService.new(
      card: card,
      inbox: inbox,
      date: params[:date],
      duration_minutes: params[:duration_minutes],
      timezone: params[:timezone],
      agent: Current.user
    ).perform

    render json: { suggestions: suggestions, ai_available: ai_credential_present? }, status: :ok
  end

  # AI: draft the meeting description/agenda from the deal context. Collection
  # route. Degrades to { description: nil, ai_available: false } when AI is off.
  def draft_invite
    authorize card, :update?

    result = Crm::Ai::DraftInviteService.new(card: card, title: params[:title]).perform

    render json: result, status: :ok
  end

  # AI: summarize a HELD meeting's outcome notes into a recap + next steps, stored
  # in metadata['ai_summary']. Member route. Degrades gracefully (never 500s).
  def summarize
    authorize @meeting.card, :update?

    result = Crm::Ai::MeetingSummaryService.new(meeting: @meeting).perform

    render json: result, status: :ok
  end

  private

  def ai_credential_present?
    Crm::Ai::Config.enabled? && Crm::Ai::CredentialResolver.new(account: Current.account).configured?
  end

  def outcome_params
    parameter_set(:meeting).permit(:outcome, :notes).to_h.with_indifferent_access
  end

  def reschedule_params
    raw = parameter_set(:meeting).permit(:starts_at, :ends_at, :timezone).to_h.with_indifferent_access
    reject_invalid_timezone!(raw[:timezone])

    timezone = Crm::Timezone::Resolver.new(
      explicit: raw[:timezone].presence || @meeting.timezone.presence,
      contact: @meeting.card&.contact,
      account: Current.account
    ).name_or_default

    {
      starts_at: parse_iso8601_with_offset!(raw[:starts_at], :starts_at),
      ends_at: parse_iso8601_with_offset!(raw[:ends_at], :ends_at),
      timezone: timezone
    }
  end

  # A client-supplied timezone must be a real IANA zone. Absent tz is fine (the
  # Resolver fills the default); a present-but-garbage tz is rejected (422) to
  # stay consistent with the strict starts_at/ends_at validation beside it,
  # instead of being silently swapped for the default.
  def reject_invalid_timezone!(raw_timezone)
    return if raw_timezone.blank?

    raise ArgumentError, 'invalid_timezone' if ActiveSupport::TimeZone[raw_timezone].blank?
  end

  def ensure_calendar_meetings_enabled
    render json: { error: 'crm.calendar_meetings.disabled' }, status: :not_found unless Crm::Config.calendar_meetings_enabled?(Current.account)
  end

  def fetch_meeting
    @meeting = visible_meetings.find(params[:id])
    authorize @meeting.card, :show?
  end

  def filtered_meetings
    scope = visible_meetings
    scope = scope.where(card_id: params[:card_id]) if params[:card_id].present?
    scope = scope.where(inbox_id: params[:inbox_id]) if params[:inbox_id].present?
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(provider: params[:provider]) if params[:provider].present?
    scope = scope.where('crm_meetings.starts_at >= ?', parsed_filter_time(:from)) if parsed_filter_time(:from).present?
    scope = scope.where('crm_meetings.starts_at <= ?', parsed_filter_time(:to)) if parsed_filter_time(:to).present?
    scope
  end

  def visible_meetings
    Current.account.crm_meetings
           .where(card_id: policy_scope(::Crm::Card).select(:id))
           .includes(:meeting_guests, :card, :inbox, :created_by, :reminder)
  end

  def card
    @card ||= policy_scope(::Crm::Card).includes(:contact, :owner, :primary_conversation).find(params[:card_id])
  end

  def inbox
    @inbox ||= Current.account.inboxes.find(params[:inbox_id])
  end

  def meeting_params
    raw = parameter_set(:meeting).permit(
      :title, :description, :starts_at, :ends_at, :timezone,
      :reminder_minutes_before, extra_guests: []
    ).to_h.with_indifferent_access

    reject_invalid_timezone!(raw[:timezone])
    timezone = Crm::Timezone::Resolver.new(
      explicit: raw[:timezone],
      contact: card&.contact,
      account: Current.account
    ).name_or_default

    raw.merge(
      starts_at: parse_iso8601_with_offset!(raw[:starts_at], :starts_at),
      ends_at: parse_iso8601_with_offset!(raw[:ends_at], :ends_at),
      timezone: timezone
    )
  end

  def parse_iso8601_with_offset!(value, field)
    raise ArgumentError, "#{field}_invalid" if value.blank?
    raise ArgumentError, "#{field}_must_include_timezone_offset" unless value.to_s.match?(ISO8601_OFFSET_REGEX)

    begin
      Time.iso8601(value.to_s)
    rescue ArgumentError
      raise ArgumentError, "#{field}_invalid"
    end
  end

  def parsed_filter_time(key)
    @parsed_filter_time ||= {}
    @parsed_filter_time[key] ||= safe_filter_time(params[key]) if params[key].present?
  rescue ArgumentError, TypeError
    @parsed_filter_time[key] = nil
  end

  def safe_filter_time(raw_value)
    parsed_value = Time.zone.parse(raw_value)
    return if parsed_value.blank?
    return unless parsed_value.year.between?(1900, 9999)

    parsed_value
  end

  def per_page
    params.fetch(:per_page, RESULTS_PER_PAGE).to_i.clamp(1, MAX_RESULTS_PER_PAGE)
  end

  def serialize(meeting)
    {
      id: meeting.id,
      card_id: meeting.card_id,
      inbox_id: meeting.inbox_id,
      title: meeting.title,
      description: stripped_description(meeting.description),
      starts_at: meeting.starts_at&.iso8601,
      ends_at: meeting.ends_at&.iso8601,
      timezone: meeting.timezone,
      status: meeting.status,
      outcome: meeting.outcome,
      outcome_notes: meeting.outcome_notes,
      outcome_recorded_at: meeting.outcome_recorded_at&.iso8601,
      provider: meeting.provider,
      online_meeting_type: meeting.online_meeting_type,
      online_meeting_url: meeting.online_meeting_url,
      reminder_id: meeting.reminder_id,
      summary: meeting.metadata.to_h['ai_summary'].presence,
      summary_at: meeting.metadata.to_h['ai_summary_at'].presence,
      guests: meeting.meeting_guests.map { |guest| serialize_guest(guest) },
      scheduled_by: serialize_user(meeting.created_by),
      created_at: meeting.created_at&.iso8601,
      updated_at: meeting.updated_at&.iso8601
    }
  end

  def serialize_guest(guest)
    {
      id: guest.id,
      email: guest.email,
      name: guest.name,
      guest_type: guest.guest_type,
      rsvp_status: guest.rsvp_status
    }
  end

  def serialize_user(user)
    return if user.blank?

    { id: user.id, name: user.name }
  end

  def stripped_description(text)
    return if text.nil?
    return Crm::Meetings::Sanitizer.strip_tags(text) if Crm::Meetings::Sanitizer.respond_to?(:strip_tags)

    ActionController::Base.helpers.strip_tags(text.to_s)
  end

  def calendar_provider_error?(error)
    calendar_provider_error_classes.any? { |error_class| error.is_a?(error_class) }
  end

  def calendar_provider_error_classes
    [
      Net::OpenTimeout,
      Net::ReadTimeout,
      Errno::ECONNREFUSED,
      (Microsoft::CalendarError if defined?(Microsoft::CalendarError)),
      (Google::CalendarError if defined?(Google::CalendarError))
    ].compact
  end
end
