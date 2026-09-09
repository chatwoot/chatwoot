class Api::V1::Accounts::CannedResponsesController < Api::V1::Accounts::BaseController
  before_action :fetch_canned_response, only: [:update, :destroy]

  def index
    render json: canned_responses, include: [:canned_response_scopes]
  end

  def create
    @canned_response = Current.account.canned_responses.new(canned_response_base_params.merge(created_by_id: current_user.id))
    scope_ids = resolved_scope_ids if @canned_response.private_response?

    if @canned_response.private_response? && no_scopes_provided?(scope_ids)
      render json: { error: 'Private canned response must be assigned to a user, team, or inbox' },
             status: :unprocessable_entity
      return
    end

    ActiveRecord::Base.transaction do
      @canned_response.save!
      build_scopes(@canned_response, scope_ids)
    end
    render json: @canned_response.as_json(include: :canned_response_scopes)
  end

  def update
    @canned_response.assign_attributes(canned_response_base_params)
    scope_ids = scope_ids_for_update

    if @canned_response.private_response? && scope_ids && no_scopes_provided?(scope_ids)
      render json: { error: 'Private canned response must be assigned to a user, team, or inbox' },
             status: :unprocessable_entity
      return
    end

    ActiveRecord::Base.transaction do
      @canned_response.save!
      replace_scopes(scope_ids)
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

  # Agents can only touch responses they can see (public, own, or shared with them); private
  # responses of other users are not accessible even though their ids are enumerable.
  def fetch_canned_response
    @canned_response = all_responses_scope.find(params[:id])
  end

  def canned_response_base_params
    params.require(:canned_response).permit(:short_code, :content, :visibility)
  end

  def build_scopes(canned_response, scope_ids)
    return unless canned_response.private_response?

    canned_response.canned_response_scopes.create!(scope_ids)
  end

  def replace_scopes(scope_ids)
    return if @canned_response.private_response? && scope_ids.nil?

    @canned_response.canned_response_scopes.destroy_all
    build_scopes(@canned_response, scope_ids)
  end

  def scope_ids_for_update
    return unless @canned_response.private_response?
    return unless @canned_response.will_save_change_to_visibility? || (current_user.administrator? && scope_params_provided?)

    resolved_scope_ids
  end

  # ids from other accounts are dropped: a membership elsewhere must not grant access here
  def account_ids_for(scope, ids)
    scope.where(id: Array(ids)).ids
  end

  def resolved_scope_ids
    {
      user_ids: current_user.administrator? ? account_ids_for(Current.account.users, params[:user_ids]) : [current_user.id],
      team_ids: current_user.administrator? ? account_ids_for(Current.account.teams, params[:team_ids]) : [],
      inbox_ids: account_ids_for(Current.account.inboxes, params[:inbox_ids])
    }
  end

  def scope_params_provided?
    %i[user_ids team_ids inbox_ids].any? { |key| params.key?(key) }
  end

  def no_scopes_provided?(scope_ids)
    return false unless current_user.administrator?

    scope_ids.values.all?(&:empty?)
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
