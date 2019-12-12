class Api::V1::Widget::InboxesController < Api::BaseController
  before_action :authorize_request

  def create
    ActiveRecord::Base.transaction do
      channel = web_widgets.create!(
        website_name: permitted_params[:website_name],
        website_url: permitted_params[:website_url]
      )
      @inbox = inboxes.create!(name: permitted_params[:website_name], channel: channel)
    end
  end

  private

  def authorize_request
    authorize ::Inbox
  end

  def inboxes
    current_account.inboxes
  end

  def web_widgets
    current_account.web_widgets
  end

  def permitted_params
    params.fetch(:website).permit(:website_name, :website_url)
  end
end
