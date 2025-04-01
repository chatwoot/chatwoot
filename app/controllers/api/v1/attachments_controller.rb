class Api::V1::AttachmentsController < ApplicationController
  before_action :set_attachment, only: [:transcribe]

  def transcribe
    return render_invalid_file_type unless @attachment.file_type == 'audio'

    begin
      transcription = TranscriptionService.transcribe_audio(@attachment)
      handle_transcription_result(transcription)
    rescue StandardError
      render_internal_error
    end
  end

  private

  def set_attachment
    @attachment = Attachment.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      error: 'Attachment não encontrado'
    }, status: :not_found
  end

  def render_invalid_file_type
    render json: {
      success: false,
      error: 'Apenas arquivos de áudio podem ser transcritos'
    }, status: :unprocessable_entity
  end

  def handle_transcription_result(transcription)
    if transcription
      @attachment.reload
      render json: {
        success: true,
        transcription: @attachment.transcription,
        message: 'Transcrição concluída com sucesso'
      }
    else
      render json: {
        success: false,
        error: 'Erro ao transcrever o áudio. Verifique os logs do servidor para mais detalhes.'
      }, status: :unprocessable_entity
    end
  end

  def render_internal_error
    render json: {
      success: false,
      error: 'Ocorreu um erro inesperado ao processar a transcrição.'
    }, status: :internal_server_error
  end
end
