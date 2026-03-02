class Api::V1::Payzah::CallbacksController < ActionController::API
  def success
    payable = find_payable(params[:trackId])

    if payable
      payable.mark_as_paid!(params.as_json)
      redirect_to payment_success_url(track_id: payable.external_payment_id), allow_other_host: true
    else
      redirect_to payment_failure_url(error: 'Payment link not found'), allow_other_host: true
    end
  end

  def error
    payable = find_payable(params[:trackId])

    if payable
      payable.mark_as_failed!(params.as_json)
      redirect_to payment_failure_url(track_id: payable.external_payment_id), allow_other_host: true
    else
      redirect_to payment_failure_url(error: 'Payment link not found'), allow_other_host: true
    end
  end

  private

  def find_payable(external_id)
    PaymentLink.find_by(external_payment_id: external_id) ||
      Order.find_by(external_payment_id: external_id)
  end
end
