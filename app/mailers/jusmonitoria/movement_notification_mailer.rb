class Jusmonitoria::MovementNotificationMailer < ApplicationMailer
  layout false

  def notification
    @html_content = params[:html_content].to_s
    @text_content = params[:text_content].presence || strip_tags(@html_content)

    mail(to: params[:to], subject: params[:subject]) do |format|
      format.html { render html: sanitize(@html_content) }
      format.text { render plain: @text_content }
    end
  end
end
