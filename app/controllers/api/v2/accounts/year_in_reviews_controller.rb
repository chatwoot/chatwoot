class Api::V2::Accounts::YearInReviewsController < Api::V1::Accounts::BaseController
  def show
    year = params[:year] || 2025
    cache_key = "year_in_review_#{Current.account.id}_#{year}"

    cached_data = Current.user.ui_settings&.dig(cache_key)

    if cached_data.present?
      render json: cached_data
    else
      builder = YearInReviewBuilder.new(
        account: Current.account,
        user_id: Current.user.id,
        year: year
      )

      data = builder.build

      ui_settings = Current.user.ui_settings || {}
      ui_settings[cache_key] = data
      Current.user.update!(ui_settings: ui_settings)

      render json: data
    end
  end
end
