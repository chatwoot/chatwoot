class Api::V1::Accounts::Integrations::HooksController < Api::V1::Accounts::BaseController
  before_action :fetch_hook, only: [:update, :destroy]
  before_action :check_authorization

  def create
    @hook = Current.account.hooks.create!(permitted_params)
  end

  def update
    @hook.update!(permitted_params.slice(:status, :settings))
  end

  def destroy
    @hook.destroy
    head :ok
  end

  private

  def fetch_hook
    @hook = Current.account.hooks.find(params[:id])
  end

  def check_authorization
    authorize(:hook)
  end

  def permitted_params
    params.require(:hook).permit(:app_id, :inbox_id, :status, settings: {})
  end
end
