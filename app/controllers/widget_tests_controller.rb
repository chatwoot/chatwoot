class WidgetTestsController < ActionController::Base
  before_action :ensure_web_widget
  before_action :ensure_widget_position
  before_action :ensure_widget_type
  before_action :ensure_widget_style
  before_action :ensure_dark_mode

  DISPLAY_PARAMS = %i[position type widget_style dark_mode].freeze

  def index
    render
  end

  def update
    @web_widget.update!(hmac_mandatory: ActiveModel::Type::Boolean.new.cast(params[:hmac_mandatory]))
    redirect_to widget_tests_path(params.permit(*DISPLAY_PARAMS).merge(inbox_id: @inbox.id))
  end

  private

  def ensure_widget_style
    @widget_style = params[:widget_style] || 'standard'
  end

  def ensure_dark_mode
    @dark_mode = params[:dark_mode] || 'light'
  end

  def ensure_widget_position
    @widget_position = params[:position] || 'left'
  end

  def ensure_widget_type
    @widget_type = params[:type] || 'expanded_bubble'
  end

  def inbox_id
    @inbox_id ||= params[:inbox_id] || params[:id] || Channel::WebWidget.first.inbox.id
  end

  def ensure_web_widget
    @inbox = Inbox.find(inbox_id)
    @web_widget = @inbox.channel
  end
end
