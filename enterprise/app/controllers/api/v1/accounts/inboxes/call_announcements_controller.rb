class Api::V1::Accounts::Inboxes::CallAnnouncementsController < Api::V1::Accounts::BaseController
  # How long an unanswered call rings before the caller is told nobody is available
  TIMEOUT_SECONDS = (10..300)

  before_action :fetch_inbox
  before_action :set_announcement
  before_action :validate_settings
  before_action :validate_timeout, if: -> { @announcement.kind == 'unanswered' }

  rescue_from CustomExceptions::InvalidAnnouncementAudio, CustomExceptions::AnnouncementGenerationFailed do |error|
    render json: { error: error.message }, status: error.http_status
  end

  def update
    @announcement.save!(enabled: @enabled, message: @message, config: @config.to_h)
    @inbox.update_account_cache
    render 'api/v1/accounts/inboxes/show'
  end

  private

  # The ring time is saved with the missed-call message
  def validate_timeout
    timeout = params[:timeout_seconds]
    unless timeout.is_a?(Integer) && TIMEOUT_SECONDS.cover?(timeout)
      return render_could_not_create_error(I18n.t('inbox.call_announcements.invalid_timeout', min: TIMEOUT_SECONDS.min, max: TIMEOUT_SECONDS.max))
    end

    @config = { 'unanswered_call_timeout_seconds' => timeout }
  end

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize @inbox, :update?
    return if @inbox.twilio? && @inbox.channel.voice_enabled?

    render_could_not_create_error(I18n.t('inbox.voice_settings.unsupported_inbox'))
  end

  def set_announcement
    raise ActiveRecord::RecordNotFound unless Voice::CallAnnouncement::KINDS.key?(params[:kind])

    @announcement = Voice::CallAnnouncement.new(@inbox, params[:kind])
  end

  # The greeting is switched on or off and needs its text when on. The missed-call and out-of-hours
  # messages are always on: an empty missed-call message is the default text, and an empty
  # out-of-hours message is the missed-call message.
  def validate_settings
    @enabled = enabled_param
    message = params[:message]
    unless [true, false].include?(@enabled) && message.is_a?(String)
      return render_could_not_create_error(I18n.t('inbox.call_announcements.invalid_settings'))
    end

    @message = message.strip
    if @enabled && @message.empty? && @announcement.kind == 'greeting'
      return render_could_not_create_error(I18n.t('inbox.call_announcements.message_required'))
    end
    return unless @message.length > Voice::CallAnnouncement::MESSAGE_MAX_LENGTH

    render_could_not_create_error(I18n.t('inbox.call_announcements.message_too_long'))
  end

  def enabled_param
    return true unless @announcement.kind == 'greeting'

    params[:enabled]
  end
end
