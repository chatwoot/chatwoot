class Api::V1::Widget::EventsController < Api::V1::Widget::BaseController
  include WidgetHelper
  include Events::Types

  def create
    Rails.configuration.dispatcher.dispatch(permitted_params[:name], Time.zone.now, contact_inbox: @contact_inbox,
                                                                                    event_info: permitted_params[:event_info].to_h.merge(event_info))
    head :no_content
  end

  def impressions_invoker
    contact_id = @contact.id
    account_id = @contact.account.id

    shop_url = fetch_shop_url_from_api(account_id)

    response = post_impressions(shop_url, contact_id)

    render json: response
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
    params.permit(:name, :website_token, event_info: {}, meta: {})
  end

  def post_impressions(shop_url, contact_id) # rubocop:disable Metrics/MethodLength
    data = {
      type: 'webWidgetOpened',
      popupId: params[:meta]['popupId'],
      browserId: params[:meta]['browserId'],
      shopUrl: shop_url,
      contactID: contact_id.to_s,
      createdAt: Time.now.utc.iso8601(3)
    }
    Rails.logger.info("responseData, #{data}")
    response = HTTParty.post(
      'https://popups.bitespeed.co/impressionsInvoker',
      body: data.to_json,
      headers: {
        'Content-Type': 'application/json'
      }
    )
    Rails.logger.info("responseData, #{response}")
  rescue StandardError => e
    Rails.logger.error "Error fetching posting impressions: #{e.message}"
    nil
  end
end
