class Api::V1::Widget::EventsController < Api::V1::Widget::BaseController
  include Events::Types

  async def create
    website_token = params[:website_token]
    Rails.configuration.dispatcher.dispatch(permitted_params[:name], Time.zone.now, contact_inbox: @contact_inbox,
                                                                                    event_info: permitted_params[:event_info].to_h.merge(event_info))
    head :no_content
    chatbot_id = ChatbotHelper.get_chatbot_id(website_token)
    await axios.post(ENV.fetch('MICROSERVICE_URL', nil) + '/cache-data', {
                       chatbotId: chatbot_id
                     })
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
