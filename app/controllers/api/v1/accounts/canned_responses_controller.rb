class Api::V1::Accounts::CannedResponsesController < Api::V1::Accounts::BaseController
  before_action :fetch_canned_response, only: [:update, :destroy]

  def index
    render json: canned_responses, include: [:canned_response_scopes]
  end

  def create
    @canned_response = find_or_init_canned_response
    @canned_response.assign_attributes(canned_response_base_params.merge(created_by_id: current_user.id))

    if @canned_response.private_response? && no_scopes_provided?
      render json: { error: 'Private canned response must be assigned to a user, team, or inbox' },
             status: :unprocessable_entity
      return
    end

    is_new = @canned_response.new_record?
    @canned_response.save!
    @canned_response.canned_response_scopes.destroy_all unless is_new
    build_scopes(@canned_response)
    render json: @canned_response.as_json(include: :canned_response_scopes)
  end

  def update
    @canned_response.assign_attributes(canned_response_base_params)

    if @canned_response.private_response? && no_scopes_provided?
      render json: { error: 'Private canned response must be assigned to a user, team, or inbox' },
             status: :unprocessable_entity
      return
    end

    ActiveRecord::Base.transaction do
      @canned_response.save!
      @canned_response.canned_response_scopes.destroy_all
      build_scopes(@canned_response)
    end
    render json: @canned_response.as_json(include: :canned_response_scopes)
  end

  def destroy
    if @canned_response.private_response?
      remove_user_from_scopes_or_destroy
    else
      @canned_response.destroy!
    end
    head :ok
  end

  private

  def remove_user_from_scopes_or_destroy
    scope = @canned_response.canned_response_scopes.find do |s|
      s.user_ids.include?(current_user.id)
    end

    if scope
      updated_user_ids = scope.user_ids - [current_user.id]

      if updated_user_ids.empty?
        scope.destroy!
      else
        scope.update!(user_ids: updated_user_ids)
      end
    end

    @canned_response.destroy! if @canned_response.reload.canned_response_scopes.empty?
  end

  def find_or_init_canned_response
    visibility = canned_response_base_params[:visibility]
    short_code = canned_response_base_params[:short_code]

    if visibility == 'private_response'
      Current.account.canned_responses.find_or_initialize_by(
        short_code: short_code,
        visibility: :private_response,
        created_by_id: current_user.id
      )
    else
      Current.account.canned_responses.find_or_initialize_by(
        short_code: short_code,
        visibility: :public_response
      )
    end
  end

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

    search = params[:search].delete("\0")
    scope.where('short_code ILIKE :search OR content ILIKE :search', search: "%#{search}%")
         .order_by_search(search)
  end
end
