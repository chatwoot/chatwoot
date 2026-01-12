class WidgetTestController < ActionController::Base
  before_action :ensure_web_widget

  def index
    render
  end

  private

  def ensure_web_widget
    inbox_id = params[:inbox_id] || Channel::WebWidget.first&.inbox&.id
    return render plain: 'No web widget found', status: :not_found unless inbox_id

    @inbox = Inbox.find(inbox_id)
    @web_widget = @inbox.channel
  rescue ActiveRecord::RecordNotFound
    render plain: 'Web widget not found', status: :not_found
  end
end

