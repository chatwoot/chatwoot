class Api::V1::Payzah::CallbacksController < ActionController::API
  def success
    payment_link = PaymentLink.find_by(external_payment_id: params[:trackId])

    if payment_link
      payment_link.mark_as_paid!(params.as_json)
      redirect_to payment_success_url(track_id: payment_link.external_payment_id), allow_other_host: true
    else
      redirect_to payment_failure_url(error: 'Payment link not found'), allow_other_host: true
    end
  end

  def error
    payment_link = PaymentLink.find_by(external_payment_id: params[:trackId])

    if payment_link
      payment_link.mark_as_failed!(params.as_json)
      redirect_to payment_failure_url(track_id: payment_link.external_payment_id), allow_other_host: true
    else
      redirect_to payment_failure_url(error: 'Payment link not found'), allow_other_host: true
    end
  end
end
