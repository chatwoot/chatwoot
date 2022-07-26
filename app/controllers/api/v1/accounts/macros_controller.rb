class Api::V1::Accounts::MacrosController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :fetch_macro, only: [:show, :update, :destroy, :execute]

  def index
    @macros = Macro.with_visibility(current_user, params)
  end

  def create
    @macro = Current.account.macros.new(macros_with_user.merge(created_by_id: current_user.id))
    @macro.set_visibility(current_user, permitted_params)
    @macro.actions = params[:actions]

    render json: { error: @macro.errors.messages }, status: :unprocessable_entity and return unless @macro.valid?

    @macro.save!
  end

  def show; end

  def destroy
    @macro.destroy!
    head :ok
  end

  def update
    ActiveRecord::Base.transaction do
      @macro.update!(macros_with_user)
      @macro.set_visibility(current_user, permitted_params)
      @macro.save!
    rescue StandardError => e
      Rails.logger.error e
      render json: { error: @macro.errors.messages }.to_json, status: :unprocessable_entity
    end
  end

  def execute
    ::MacrosExecutionJob.perform_later(@macro, conversation_ids: params[:conversation_ids], user: Current.user)

    head :ok
  end

  def permitted_params
    params.permit(
      :name, :account_id, :visibility,
      actions: [:action_name, { action_params: [] }]
    )
  end

  def macros_with_user
    permitted_params.merge(updated_by_id: current_user.id)
  end

  def fetch_macro
    @macro = Current.account.macros.find_by(id: params[:id])
  end
end
