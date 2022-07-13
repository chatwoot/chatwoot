class Api::V1::Accounts::MacrosController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :fetch_macro, only: [:show, :update, :destroy]

  def index
    @macros = Macro.with_visibility(params)
  end

  def create
    @macro = Current.account.macros.new(macros_with_user)
    @macro.set_visibility(current_user, macros_permit)
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
      @macro.update!(macros_permit)
      @macro.set_visibility(current_user, macros_permit)
      @macro.save!
    rescue StandardError => e
      Rails.logger.error e
      render json: { error: @macro.errors.messages }.to_json, status: :unprocessable_entity
    end
  end

  def macros_permit
    params.permit(
      :name, :account_id, :visibility, :created_by_id,
      actions: [:action_name, { action_params: [] }]
    )
  end

  def macros_with_user
    macros_permit.merge(updated_by_id: current_user.id)
  end

  def fetch_macro
    @macro = Current.account.macros.find_by(id: params[:id])
  end
end
