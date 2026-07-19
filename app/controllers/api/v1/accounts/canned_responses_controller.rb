class Api::V1::Accounts::CannedResponsesController < Api::V1::Accounts::BaseController
  before_action :fetch_canned_response, only: [:update, :destroy]
  before_action :check_authorization, only: [:update, :destroy]

  def index
    render json: canned_responses
  end

  def create
    authorize(CannedResponse)
    @canned_response = Current.account.canned_responses.new(
      canned_response_params.except(:visibility).merge(created_by_id: current_user.id)
    )
    @canned_response.set_visibility(current_user, canned_response_params)
    @canned_response.save!
    render json: @canned_response
  end

  def update
    @canned_response.assign_attributes(canned_response_params.except(:visibility))
    @canned_response.set_visibility(current_user, canned_response_params)
    @canned_response.save!
    render json: @canned_response
  end

  def destroy
    @canned_response.destroy!
    head :ok
  end

  private

  def fetch_canned_response
    @canned_response = Current.account.canned_responses.find(params[:id])
  end

  def check_authorization
    authorize(@canned_response) if @canned_response.present?
  end

  def canned_response_params
    params.require(:canned_response).permit(:short_code, :content, :category, :visibility)
  end

  def canned_responses
    records = CannedResponse.with_visibility(current_user, params)
    records = records.where(category: params[:category]) if params[:category].present?

    if params[:search]
      records
        .where(
          'short_code ILIKE :search OR content ILIKE :search OR COALESCE(category, \'\') ILIKE :search',
          search: "%#{params[:search]}%"
        )
        .order_by_search(params[:search])
    else
      records.order(:id)
    end
  end
end
