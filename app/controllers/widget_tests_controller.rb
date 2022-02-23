class WidgetTestsController < ActionController::Base
  before_action :set_web_widget

  def index
    render
  end

  private

  def inbox_id
    @inbox_id ||= params[:inbox_id] || Channel::WebWidget.first.inbox.id
  end

  def set_web_widget
    @inbox = Inbox.find(inbox_id)
    @web_widget = @inbox.channel
  end
end
