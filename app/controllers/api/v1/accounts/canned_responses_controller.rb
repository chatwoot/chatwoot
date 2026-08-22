class Api::V1::Accounts::CannedResponsesController < Api::V1::Accounts::BaseController
  before_action :fetch_canned_response, only: [:update, :destroy, :approve, :reject]
  before_action :check_authorization, only: [:update, :destroy, :approve, :reject]

  def index
    render json: canned_responses
  end

  def create
    authorize(CannedResponse)
    @canned_response = Current.account.canned_responses.new(
      canned_response_params.except(:visibility, :approval_status).merge(created_by_id: current_user.id)
    )
    @canned_response.visibility = canned_response_params[:visibility] if canned_response_params[:visibility].present?
    @canned_response.apply_create_rules(current_user)
    @canned_response.save!
    render json: @canned_response
  end

  def update
    @canned_response.assign_attributes(canned_response_params.except(:visibility, :approval_status))
    if current_user.administrator? && canned_response_params[:visibility].present?
      @canned_response.visibility = canned_response_params[:visibility]
    end
    @canned_response.apply_update_rules(current_user)
    @canned_response.save!
    render json: @canned_response
  end

  def approve
    visibility = params[:visibility].presence || 'personal'
    unless %w[personal global].include?(visibility)
      render json: { error: 'Invalid visibility' }, status: :unprocessable_entity
      return
    end

    @canned_response.approve!(current_user, visibility: visibility)
    render json: @canned_response
  end

  def reject
    @canned_response.reject!(current_user)
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
    params.require(:canned_response).permit(:short_code, :content, :category, :visibility, :approval_status)
  end

  def canned_responses
    # Slash/`/` search and reply picker pass usable=true (approved only).
    query_params = params.to_unsafe_h
    query_params[:usable] = true if params[:search].present? && params[:usable].nil?

    records = CannedResponse.with_visibility(current_user, query_params)
    records = records.where(category: params[:category]) if params[:category].present?

    if params[:search]
      search = params[:search].delete("\0")
      records
        .where(
          'short_code ILIKE :search OR content ILIKE :search OR COALESCE(category, \'\') ILIKE :search',
          search: "%#{search}%"
        )
        .order_by_search(search)
    else
      records.order(:id)
    end
  end
end
