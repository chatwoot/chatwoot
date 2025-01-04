class Api::V1::Accounts::ResponsesController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :check_authorization
  before_action :find_response, only: [:show, :update, :destroy]
  before_action :set_current_page, only: [:index, :search]

  RESULTS_PER_PAGE = 25

  def index
    @responses = account.responses.page(@current_page).per(RESULTS_PER_PAGE).order(created_at: :desc)
    @responses_count = account.responses.count
  end

  def search
    responses = account.responses.where('question ILIKE :query OR answer ILIKE :query', query: "%#{params[:query]}%")
    @responses = responses.page(@current_page).per(RESULTS_PER_PAGE) if responses.present?
    @responses_count = responses.count
  end

  def show
    render json: @response
  end

  def create
    response = account.responses.new(response_params)
    if response.save
      render json: response, status: :created
    else
      render json: { errors: response.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @response.update(response_params)
      render json: @response
    else
      render json: { errors: @response.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @response.destroy
    head :no_content
  end

  private

  def response_params
    params.require(:response).permit(:question, :answer, :document_id, :assistant_id)
  end

  def find_response
    @response = account.responses.find(params[:id])
  end

  def set_current_page
    @current_page = params[:page] || 1
  end
end
