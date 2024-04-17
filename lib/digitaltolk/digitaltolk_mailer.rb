class Digitaltolk::DigitaltolkMailer < ApplicationMailer
  def send_email(params)
    return unless smtp_config_set_or_development?
    return if params[:to].blank?
    return if params[:from].blank?

    @form_name = params[:form_name]
    @content = params[:data]

    email_params = {
      to: params[:to],
      reply_to: params[:from],
      subject: params[:subject]
    }

    mail(email_params) do |format|
      format.html do
        render 'mailers/digitaltolk_mailer/send_email', layout: false
      end
    end
  end
end
