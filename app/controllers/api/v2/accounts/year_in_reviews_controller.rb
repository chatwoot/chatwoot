class Api::V2::Accounts::YearInReviewsController < Api::V1::Accounts::BaseController
  def show
    user_id = Current.user.id

    builder = YearInReviewBuilder.new(
      account: Current.account,
      user_id: user_id,
      year: 2025
    )

    render json: builder.build
  end
end
