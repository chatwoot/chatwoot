class Api::V1::Accounts::CannedResponsesController < Api::V1::Accounts::BaseController
  before_action :fetch_canned_response, only: [:update, :destroy]

  def index
    responses = canned_responses.map do |response|
      response.as_json.merge(attachments: response.file_base_data)
    end
    render json: responses
  end

  def create
    @canned_response = Current.account.canned_responses.new(canned_response_params)
    @canned_response.save!
    process_attachments
    render json: canned_response_with_files
  end

  def update
    @canned_response.update!(canned_response_params)
    process_attachments
    render json: canned_response_with_files
  end

  def destroy
    @canned_response.destroy!
    head :ok
  end

  private

  def fetch_canned_response
    @canned_response = Current.account.canned_responses.find(params[:id])
  end

  def canned_response_params
    params.require(:canned_response).permit(:short_code, :content)
  end

  def process_attachments
    return unless params.key?(:attachments)

    @canned_response.files.purge

    return if params[:attachments].blank?

    params[:attachments].each do |blob_id|
      blob = ActiveStorage::Blob.find_by(id: blob_id)
      @canned_response.files.attach(blob) if blob.present?
    end
  end

  def canned_response_with_files
    @canned_response.as_json.merge(attachments: @canned_response.file_base_data)
  end

  def canned_responses
    if params[:search]
      Current.account.canned_responses
             .where('short_code ILIKE :search OR content ILIKE :search', search: "%#{params[:search]}%")
             .order_by_search(params[:search])

    else
      Current.account.canned_responses
    end
  end
end
