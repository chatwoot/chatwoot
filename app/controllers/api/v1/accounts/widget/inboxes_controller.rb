class Api::V1::Accounts::Widget::InboxesController < Api::BaseController
  before_action :authorize_request
  before_action :set_web_widget_channel, only: [:update]
  before_action :set_inbox, only: [:update]

  def create
    ActiveRecord::Base.transaction do
      channel = web_widgets.create!(
        website_name: permitted_params[:website][:website_name],
        website_url: permitted_params[:website][:website_url],
        widget_color: permitted_params[:website][:widget_color]
      )
      @inbox = inboxes.create!(name: permitted_params[:website][:website_name], channel: channel)
    end
  end

  def update
    @channel.update!(
      widget_color: permitted_params[:website][:widget_color]
    )
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

  def set_web_widget_channel
    @channel = web_widgets.find_by(id: permitted_params[:id])
  end

  def set_inbox
    @inbox = @channel.inbox
  end

  def permitted_params
    params.permit(:id, website: [:website_name, :website_url, :widget_color])
  end
end
