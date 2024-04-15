class Digitaltolk::DigitaltolkMailer < ApplicationMailer
  def send_email(params)
    return unless smtp_config_set_or_development?
    return unless params.dig(:to).present?
    return unless params.dig(:from).present?

    @form_name = params.dig(:form_name)
    @content = params.dig(:data)

    email_params = {
      to: params.dig(:to),
      reply_to: params.dig(:from),
      subject: params.dig(:subject)
    }

    mail(email_params) do |format|
      format.html do
        render 'mailers/digitaltolk_mailer/send_email', layout: false
      end
    end
  end
end
