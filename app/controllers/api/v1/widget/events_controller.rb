class Api::V1::Widget::EventsController < Api::V1::Widget::BaseController
  include Events::Types

  def create
    Rails.configuration.dispatcher.dispatch(permitted_params[:name], Time.zone.now, contact_inbox: @contact_inbox, event_info: event_info)
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
    params.permit(:name, :website_token)
  end
end
