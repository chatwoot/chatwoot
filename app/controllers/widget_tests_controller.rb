class WidgetTestsController < ActionController::Base
  before_action :ensure_web_widget

  def index
    render
  end

  private

  def inbox_id
    @inbox_id ||= params[:inbox_id] || Channel::WebWidget.first.inbox.id
  end

  def ensure_web_widget
    @inbox = Inbox.find(inbox_id)
    @web_widget = @inbox.channel
  end
end
