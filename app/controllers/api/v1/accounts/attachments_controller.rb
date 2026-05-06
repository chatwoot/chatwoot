class Api::V1::Accounts::AttachmentsController < Api::V1::Accounts::BaseController
  before_action :set_attachment
  before_action :authorize_conversation

  def playback
    return head :not_found unless @attachment.audio? && @attachment.file.attached?

    blob = Audio::Mp3TranscodeService.new(attachment: @attachment).perform
    redirect_to url_for(blob)
  rescue Audio::Mp3TranscodeService::TranscodeError => e
    Rails.logger.warn("[AUDIO_PLAYBACK] MP3 transcode failed for attachment #{@attachment.id}: #{e.message}")
    redirect_to @attachment.file_url
  end

  private

  def set_attachment
    @attachment = Attachment
                  .includes(message: :conversation)
                  .where(account_id: Current.account.id)
                  .find(params[:id])
  end

  def authorize_conversation
    authorize @attachment.message.conversation, :show?
  end
end
