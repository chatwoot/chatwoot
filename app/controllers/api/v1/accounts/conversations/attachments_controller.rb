class Api::V1::Accounts::Conversations::AttachmentsController < Api::V1::Accounts::Conversations::BaseController
  before_action :set_message
  before_action :set_attachment
  before_action :validate_meta_size, only: [:update]
  before_action :validate_transcribed_text, only: [:update]

  MAX_META_SIZE = 16.kilobytes

  def update
    @attachment.update!(permitted_params)
    record_transcription
    @attachment.message.send_update_event
  end

  private

  # Where a recording belongs to something that shows its own transcription, the text
  # written here is carried there before the message goes out again. Nothing does in the
  # open-source edition.
  def record_transcription; end

  def set_message
    @message = @conversation.messages.find(params[:message_id])
  end

  def set_attachment
    @attachment = @message.attachments.find(params[:id])
  end

  def permitted_params
    params.permit(meta: {})
  end

  def validate_meta_size
    return if params[:meta].blank?

    return unless params[:meta].to_json.bytesize > MAX_META_SIZE

    render json: { error: "Metadata size exceeds maximum allowed (#{MAX_META_SIZE / 1024}KB)" }, status: :unprocessable_entity
  end

  # `meta` is an object, and the transcription in it is text wherever it is read, the
  # call's included: a `false` or a number stored there would come back as the string
  # "false" or "42". Anything else is refused before a write, rather than half-applied.
  def validate_transcribed_text
    meta = params[:meta]
    return if meta.nil?
    return render json: { error: 'meta must be an object' }, status: :unprocessable_entity unless meta.is_a?(ActionController::Parameters)
    return if !meta.key?(:transcribed_text) || meta[:transcribed_text].is_a?(String)

    render json: { error: 'transcribed_text must be a string' }, status: :unprocessable_entity
  end
end

Api::V1::Accounts::Conversations::AttachmentsController.prepend_mod_with('Api::V1::Accounts::Conversations::AttachmentsController')
