class Api::V1::Accounts::InternalChat::SearchController < Api::V1::Accounts::InternalChat::BaseController
  def show
    authorize InternalChat::Channel, :index?

    result = InternalChat::SearchService.new(
      current_user: Current.user,
      current_account: Current.account,
      params: search_params
    ).perform

    render json: result
  end

  private

  def search_params
    params.permit(:q, :page)
  end
end
