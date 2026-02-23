class Api::V1::Accounts::CannedResponsesController < Api::V1::Accounts::BaseController
  before_action :fetch_canned_response, only: [:update, :destroy]

  def index
    render json: canned_responses, include: [:canned_response_scopes]
  end

  def create
    @canned_response = Current.account.canned_responses.new(canned_response_base_params.merge(created_by_id: current_user.id))

    if @canned_response.private_response? && no_scopes_provided?
      render json: { error: 'Private canned response must be assigned to a user, team, or inbox' },
             status: :unprocessable_entity
      return
    end

    @canned_response.save!
    build_scopes(@canned_response)
    render json: @canned_response.as_json(include: :canned_response_scopes)
  end

  def update
    @canned_response.update!(canned_response_base_params)
    @canned_response.canned_response_scopes.destroy_all

    if @canned_response.private_response? && no_scopes_provided?
      render json: { error: 'Private canned response must be assigned to a user, team, or inbox' },
             status: :unprocessable_entity
      return
    end

    build_scopes(@canned_response)
    render json: @canned_response.as_json(include: :canned_response_scopes)
  end

  def destroy
    @canned_response.destroy!
    head :ok
  end

  private

  def fetch_canned_response
    @canned_response = Current.account.canned_responses.find(params[:id])
  end

  def canned_response_base_params
    params.require(:canned_response).permit(:short_code, :content, :visibility)
  end

  def build_scopes(canned_response)
    return unless canned_response.private_response?

    user_ids  = current_user.administrator? ? Array(params[:user_ids]).map(&:to_i) : [current_user.id]
    team_ids  = current_user.administrator? ? Array(params[:team_ids]).map(&:to_i) : []
    inbox_ids = Array(params[:inbox_ids]).map(&:to_i)

    canned_response.canned_response_scopes.create!(
      user_ids: user_ids,
      team_ids: team_ids,
      inbox_ids: inbox_ids
    )
  end

  def no_scopes_provided?
    return false unless current_user.administrator?

    Array(params[:user_ids]).empty? &&
      Array(params[:team_ids]).empty? &&
      Array(params[:inbox_ids]).empty?
  end

  def canned_responses
    apply_search(base_scope)
  end

  def base_scope
    params[:all] ? all_responses_scope : filtered_scope
  end

  def all_responses_scope
    return Current.account.canned_responses if current_user.administrator?

    Current.account.canned_responses
           .where(created_by_id: current_user.id)
           .or(Current.account.canned_responses.accessible_to(current_user))
  end

  def filtered_scope
    Current.account.canned_responses
           .accessible_to(current_user, inbox_id: params[:inbox_id])
  end

  def apply_search(scope)
    scope = scope.includes(:canned_response_scopes)
    return scope unless params[:search]

    scope.where('short_code ILIKE :search OR content ILIKE :search', search: "%#{params[:search]}%")
         .order_by_search(params[:search])
  end
end
