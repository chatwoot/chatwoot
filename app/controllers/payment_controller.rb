class PaymentController < ApplicationController
  layout 'payment'

  def success
    @payment_link = find_payable(params[:track_id])

    return redirect_to payment_failure_path(error: 'Payment link not found') unless @payment_link
  end

  def failure
    @payment_link = find_payable(params[:track_id]) if params[:track_id]
    @error_message = params[:error]
  end

  private

  def find_payable(external_id)
    PaymentLink.find_by(external_payment_id: external_id) ||
      Order.find_by(external_payment_id: external_id)
  end
end
