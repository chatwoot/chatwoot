module Concerns::CaptainCallActions
  # Twilio voice only: whether Captain answers inbound calls, and which assistant (CW-7419). The assistant is
  # the inbox's Captain link, the same one Captain → Inboxes sets, so it also answers the inbox's messages.
  def set_captain_calls
    return unless ensure_calling_supported && ensure_captain_calls_params

    ActiveRecord::Base.transaction do
      link_captain_assistant(Current.account.captain_assistants.find(params[:captain_assistant_id])) if params[:captain_assistant_id].present?
      save_captain_call_settings
    end
    @inbox.update_account_cache # bump inbox cache key so the cached inbox list refetches the new settings
    head :ok
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end

  private

  def captain_answers_calls_param
    ActiveModel::Type::Boolean.new.cast(params[:captain_answers_calls])
  end

  def ensure_captain_calls_params
    error = if !@inbox.twilio?
              'Captain can answer calls only on Twilio voice inboxes'
            elsif captain_answers_calls_param && params[:captain_assistant_id].blank?
              'Choose the Captain assistant that answers calls'
            elsif params[:captain_voice].present? && Voice::Captain::AssistantConfig::VOICES.exclude?(params[:captain_voice])
              'Choose one of the listed voices'
            end
    return true if error.nil?

    render_could_not_create_error(error)
    false
  end

  # An inbox has one Captain assistant, so a different one replaces the current link
  def link_captain_assistant(assistant)
    return if @inbox.captain_assistant == assistant

    CaptainInbox.where(inbox: @inbox).destroy_all
    CaptainInbox.create!(inbox: @inbox, captain_assistant: assistant)
  end

  def save_captain_call_settings
    settings = { 'captain_answers_calls' => captain_answers_calls_param }
    settings['captain_voice'] = params[:captain_voice] if params[:captain_voice].present?

    channel = @inbox.channel
    channel.provider_config = (channel.provider_config || {}).merge(settings)
    channel.save!(validate: false)
  end
end
