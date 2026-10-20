# What an inbound caller hears while waiting for an agent: the uploaded waiting audio, and the
# beep when an agent joins
class Api::V1::Accounts::Inboxes::CallWaitingController < Api::V1::Accounts::BaseController
  CONTENT_TYPES = %w[audio/mpeg audio/wav audio/x-wav audio/wave].freeze
  MAX_SIZE = 10.megabytes

  before_action :fetch_inbox
  before_action :validate_join_beep, only: :update
  before_action :validate_audio, only: :upload_audio

  def update
    channel = @inbox.channel
    channel.update!(provider_config: channel.provider_config.merge('call_join_beep_enabled' => params[:join_beep_enabled]))
    render_inbox
  end

  def upload_audio
    @inbox.call_waiting_audio.attach(params[:audio])
    render_inbox
  end

  def remove_audio
    @inbox.call_waiting_audio.purge_later
    render_inbox
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize @inbox, :update?
    return if @inbox.twilio? && @inbox.channel.voice_enabled?

    render_could_not_create_error(I18n.t('inbox.call_waiting.unsupported_inbox'))
  end

  def validate_join_beep
    return if [true, false].include?(params[:join_beep_enabled])

    render_could_not_create_error(I18n.t('inbox.call_waiting.invalid_join_beep'))
  end

  def validate_audio
    audio = params[:audio]
    return render_could_not_create_error(I18n.t('inbox.call_waiting.invalid_file')) unless uploaded_audio?(audio)
    return unless audio.size > MAX_SIZE

    render_could_not_create_error(I18n.t('inbox.call_waiting.too_large'))
  end

  def uploaded_audio?(audio) = audio.is_a?(ActionDispatch::Http::UploadedFile) && CONTENT_TYPES.include?(audio.content_type)

  def render_inbox
    @inbox.update_account_cache
    render 'api/v1/accounts/inboxes/show'
  end
end
