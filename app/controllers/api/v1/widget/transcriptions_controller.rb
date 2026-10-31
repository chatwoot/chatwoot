class Api::V1::Widget::TranscriptionsController < Api::V1::Widget::BaseController
  # Formats the widget recorder produces, plus mp3/wav; all accepted by OpenAI transcription.
  SUPPORTED_AUDIO_TYPES = %w[audio/webm audio/ogg audio/mp4 audio/mpeg audio/wav].freeze

  def create
    return render_unavailable unless @web_widget.audio_transcription_enabled?

    audio = params[:audio]
    return render_error('No audio provided', :unprocessable_entity) unless audio.is_a?(ActionDispatch::Http::UploadedFile)
    return render_error('Unsupported audio format', :unprocessable_entity) unless supported_audio_type?(audio)

    result = Messages::WidgetAudioTranscriptionService.new(audio, account: @web_widget.account).perform

    if result[:success]
      render json: { transcription: result[:transcription] }
    else
      render_error(result[:error], :unprocessable_entity)
    end
  rescue StandardError => e
    Rails.logger.error("Widget audio transcription failed: #{e.message}")
    render_error('Transcription service is unavailable', :service_unavailable)
  end

  private

  # Compares the media type only, ignoring parameters such as "; codecs=opus".
  def supported_audio_type?(audio)
    SUPPORTED_AUDIO_TYPES.include?(Rack::MediaType.type(audio.content_type))
  end

  def render_unavailable
    render_error('Audio transcription is not enabled', :forbidden)
  end

  def render_error(message, status)
    render json: { error: message }, status: status
  end
end
