class Api::V1::Accounts::Conversations::DirectUploadsController < ActiveStorage::DirectUploadsController
  before_action :current_account
  before_action :conversation

  def create
    return if @contact.nil? || @current_account.nil?

    blob = ActiveStorage::Blob.create_before_direct_upload!(**blob_args)
    render json: direct_upload_json(blob)
  end

  private

  def blob_args
    params.require(:blob).permit(:filename, :byte_size, :checksum, :content_type, metadata: {}).to_h.symbolize_keys
  end

  def direct_upload_json(blob)
    blob.as_json(root: false, methods: :signed_id).merge(direct_upload: {
                                                           url: blob.service_url_for_direct_upload,
                                                           headers: blob.service_headers_for_direct_upload
                                                         })
  end

  def conversation
    @conversation ||= Current.account.conversations.find_by(display_id: params[:conversation_id])
    authorize @conversation.inbox, :show?
  end
end
