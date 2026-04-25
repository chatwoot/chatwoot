class Api::V1::Accounts::Kanban::BoardsController < Api::V1::Accounts::BaseController
  before_action :find_or_create_board

  def show
    authorize @board
    render 'api/v1/accounts/kanban/boards/show'
  end

  private

  def find_or_create_board
    @board = Current.account.kanban_boards.find_or_create_by!(user: current_user)
  end
end
