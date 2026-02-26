class Api::V1::Accounts::OrderNotesController < Api::V1::Accounts::BaseController
  before_action :set_order
  before_action :set_note, only: [:destroy]

  def index
    @notes = @order.order_notes.latest.includes(:user)
  end

  def create
    @note = @order.order_notes.create!(note_params)
  end

  def destroy
    @note.destroy!
    head :ok
  end

  private

  def set_order
    @order = Current.account.orders.find(params[:order_id])
    authorize @order
  end

  def set_note
    @note = @order.order_notes.find(params[:id])
  end

  def note_params
    params.require(:order_note).permit(:content).merge(user_id: Current.user.id)
  end
end
