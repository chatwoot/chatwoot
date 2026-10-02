class Api::V1::Widget::EventsController < Api::V1::Widget::BaseController
  include Events::Types
  # Both events reach listeners that need the contact inbox: campaigns start a conversation on it,
  # and webwidget_triggered webhooks/agent bots receive it.
  before_action :ensure_contact

  def create
    Rails.configuration.dispatcher.dispatch(permitted_params[:name], Time.zone.now, contact_inbox: @contact_inbox,
                                                                                    event_info: permitted_params[:event_info].to_h.merge(event_info))
    head :no_content
  end

  private

  def event_info
    {
      widget_language: params[:locale],
      browser_language: browser.accept_language.first&.code,
      browser: browser_params
    }
  end

  def permitted_params
    params.permit(:name, :website_token, event_info: {})
  end
end
