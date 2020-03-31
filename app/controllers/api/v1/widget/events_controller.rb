class Api::V1::Widget::EventsController < Api::V1::Widget::BaseController
  include Events::Types
  before_action :set_web_widget
  before_action :set_contact

  def create
    Rails.configuration.dispatcher.dispatch(permitted_params[:name], Time.zone.now, contact_inbox: @contact_inbox)
    head :no_content
  end

  private

  def permitted_params
    params.permit(:name, :website_token)
  end
end
