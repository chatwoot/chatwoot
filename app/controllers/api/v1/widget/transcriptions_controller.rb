class Api::V1::Widget::TranscriptionsController < Api::V1::Widget::BaseController
  def create
    return render_unavailable unless @web_widget.audio_transcription_enabled?
    return render_error('No audio provided', :unprocessable_entity) if params[:audio].blank?

    result = Messages::WidgetAudioTranscriptionService.new(params[:audio]).perform

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

  def render_unavailable
    render_error('Audio transcription is not enabled', :forbidden)
  end

  def render_error(message, status)
    render json: { error: message }, status: status
  end
end
