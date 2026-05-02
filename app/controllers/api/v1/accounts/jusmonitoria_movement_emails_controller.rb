class Api::V1::Accounts::JusmonitoriaMovementEmailsController < Api::V1::Accounts::BaseController
  def create
    validation_error = required_payload_error
    return render json: { error: validation_error }, status: :unprocessable_entity if validation_error
    return head :too_many_requests unless Current.account.within_email_rate_limit?

    enqueue_email
    Current.account.increment_email_sent_count

    render json: { queued: true }, status: :accepted
  end

  private

  def permitted_params
    params.permit(:to, :subject, :html_content, :text_content)
  end

  def required_payload_error
    return 'to is required' if permitted_params[:to].blank?
    return 'subject is required' if permitted_params[:subject].blank?
    return 'html_content is required' if permitted_params[:html_content].blank?

    nil
  end

  def enqueue_email
    Jusmonitoria::MovementNotificationMailer.with(
      account: Current.account,
      to: permitted_params[:to],
      subject: permitted_params[:subject],
      html_content: permitted_params[:html_content],
      text_content: permitted_params[:text_content]
    ).notification.deliver_later
  end
end
