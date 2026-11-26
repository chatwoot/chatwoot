class Api::V1::Accounts::CannedResponsesController < Api::V1::Accounts::BaseController
  before_action :fetch_canned_response, only: [:update, :destroy]
  before_action :validate_files, only: [:create, :update]

  def index
    @canned_responses = canned_responses.with_attached_files
  end

  def create
    @canned_response = Current.account.canned_responses.new(canned_response_params)
    @canned_response.save!
  end

  def update
    @canned_response.update!(canned_response_params)
  end

  def destroy
    @canned_response.destroy!
    head :ok
  end

  private

  def fetch_canned_response
    @canned_response = Current.account.canned_responses.find(params[:id])
  end

  def validate_files
    return unless params.key?(:files)

    render_could_not_create_error(I18n.t('errors.attachments.invalid')) unless file_blobs&.all?
  end

  def canned_response_params
    permitted = params.require(:canned_response).permit(:short_code, :content)
    file_blobs ? permitted.merge(files: file_blobs) : permitted
  end

  def file_blobs
    signed_ids = params.permit(files: [])[:files]
    return if signed_ids.nil?

    @file_blobs ||= signed_ids.uniq.map { |signed_id| ActiveStorage::Blob.find_signed(signed_id.to_s) }
  end

  def canned_responses
    if params[:search]
      search = params[:search].delete("\0")
      Current.account.canned_responses
             .where('short_code ILIKE :search OR content ILIKE :search', search: "%#{search}%")
             .order_by_search(search)

    else
      Current.account.canned_responses
    end
  end
end
