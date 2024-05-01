class Api::V1::Accounts::SalesPipelines::BoardsController < Api::V1::Accounts::BaseController
  def index
    @boards = Current.account.stages.where(disabled: false).order(:id)
    render json: @boards.to_json
  end
end
