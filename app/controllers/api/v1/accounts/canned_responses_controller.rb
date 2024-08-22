class Api::V1::Accounts::CannedResponsesController < Api::V1::Accounts::BaseController
  include ::FileTypeHelper
  include ::AttachmentConcern
  include RequestExceptionHandler

  before_action :fetch_canned_response, only: [:update, :destroy]

  def index
    @canned_responses = fetch_canned_responses
  end

  def create
    account = Current.account
    cb = CannedResponseBuilder.new(account, canned_response_params)
    @canned_response = cb.perform
  end

  def update
    @canned_response.update!(canned_response_params.except(:attachments))
    process_attachments_to_be_added(
      resource: @canned_response,
      call_remove_handler: true,
      params: canned_response_params
    )
    @canned_response.save!
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
    params.require(:canned_response).permit(:short_code, :content, attachments: [])
  end

  def fetch_canned_responses
    if params[:search]
      Current.account.canned_responses
             .where('short_code ILIKE :search OR content ILIKE :search', search: "%#{params[:search]}%")
             .order_by_search(params[:search])

    else
      Current.account.canned_responses
    end
  end
end
