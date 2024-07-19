class Api::V1::Accounts::BaseController < Api::BaseController
  include SwitchLocale
  include EnsureCurrentAccountHelper
  before_action :current_account
  around_action :switch_locale_using_account_locale

  private

  def require_date_range_for_parquet_request
    if params[:export_as_parquet]
      if params[:since].blank? || params[:until].blank?
        error = 'since and until params are required when exporting parquet files'
        render json: { error: error }, status: :unprocessable_entity and return
      end
    end
  end
end
