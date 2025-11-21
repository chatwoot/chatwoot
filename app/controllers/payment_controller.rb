class PaymentController < ApplicationController
  layout 'payment'

  def success
    @payment_link = PaymentLink.find_by(external_payment_id: params[:track_id])

    return redirect_to payment_failure_path(error: 'Payment link not found') unless @payment_link
  end

  def failure
    @payment_link = PaymentLink.find_by(external_payment_id: params[:track_id]) if params[:track_id]
    @error_message = params[:error]
  end
end
