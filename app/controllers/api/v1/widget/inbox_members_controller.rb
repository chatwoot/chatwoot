class Api::V1::Widget::InboxMembersController < Api::V1::Widget::BaseController
  skip_before_action :set_contact

  def index
    @inbox_members = @web_widget.inbox.inbox_members.includes(:user)
  end

  private

  def permitted_params
    params.permit(:website_token)
  end
end
