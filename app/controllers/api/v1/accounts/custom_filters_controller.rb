class Api::V1::Accounts::CustomFiltersController < Api::V1::Accounts::BaseController
  protect_from_forgery with: :null_session
  before_action :fetch_custom_filters, except: [:create]
  before_action :fetch_custom_filter, only: [:show, :update, :destroy]
  DEFAULT_FILTER_TYPE = 'conversation'.freeze

  def index; end

  def show; end

  def create
    @custom_filter = current_user.custom_filters.create!(
      permitted_payload.merge(account_id: Current.account.id)
    )
  end

  def update
    @custom_filter.update!(permitted_payload)
  end

  def destroy
    @custom_filter.destroy
    head :no_content
  end

  private

  def fetch_custom_filters
    @custom_filters = current_user.custom_filters.where(
      account_id: Current.account.id,
      filter_type: permitted_params[:filter_type] || DEFAULT_FILTER_TYPE
    )
  end

  def fetch_custom_filter
    @custom_filter = @custom_filters.find(permitted_params[:id])
  end

  def permitted_payload
    params.require(:custom_filter).permit(
      :name,
      :filter_type,
      query: {}
    )
  end

  def permitted_params
    params.permit(:id, :filter_type)
  end
end
