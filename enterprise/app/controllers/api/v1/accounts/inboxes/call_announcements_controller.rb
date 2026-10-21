class Api::V1::Accounts::Inboxes::CallAnnouncementsController < Api::V1::Accounts::BaseController
  # How long an unanswered call rings before the caller is told nobody is available
  TIMEOUT_SECONDS = (10..300)

  before_action :fetch_inbox
  before_action :set_announcement
  before_action :validate_settings
  before_action :validate_timeout, if: -> { @announcement.kind == 'unanswered' }

  def update
    @announcement.save!(enabled: params[:enabled], message: @message, config: timeout_config)
    @inbox.update_account_cache
    render 'api/v1/accounts/inboxes/show'
  end

  private

  # The ring time is saved with the no-answer announcement, whether or not it is on
  def validate_timeout
    timeout = params[:timeout_seconds]
    return if timeout.is_a?(Integer) && TIMEOUT_SECONDS.cover?(timeout)

    render_could_not_create_error(I18n.t('inbox.call_announcements.invalid_timeout', min: TIMEOUT_SECONDS.min, max: TIMEOUT_SECONDS.max))
  end

  def timeout_config
    return {} unless @announcement.kind == 'unanswered'

    { 'unanswered_call_timeout_seconds' => params[:timeout_seconds] }
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

  def validate_settings
    enabled = params[:enabled]
    message = params[:message]
    unless [true, false].include?(enabled) && message.is_a?(String)
      return render_could_not_create_error(I18n.t('inbox.call_announcements.invalid_settings'))
    end

    @message = message.strip
    return render_could_not_create_error(I18n.t('inbox.call_announcements.message_required')) if enabled && @message.empty?
    return unless @message.length > Voice::CallAnnouncement::MESSAGE_MAX_LENGTH

    render_could_not_create_error(I18n.t('inbox.call_announcements.message_too_long'))
  end
end
