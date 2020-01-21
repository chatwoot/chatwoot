class Api::V1::Widget::InboxMembersController < Api::V1::Widget::BaseController
  before_action :set_web_widget

  def index
    @inbox_members = @web_widget.inbox.inbox_members.includes(:user)
  end

  private

  def permitted_params
    params.permit(:website_token)
  end
end
