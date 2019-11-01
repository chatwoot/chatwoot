class WidgetTestsController < ActionController::Base
  before_action :set_web_widget

  def index
    render
  end

  private

  def set_web_widget
    @web_widget = Channel::WebWidget.first
  end
end
