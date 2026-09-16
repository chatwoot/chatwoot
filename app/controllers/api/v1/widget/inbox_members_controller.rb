class Api::V1::Widget::InboxMembersController < Api::V1::Widget::BaseController
  skip_before_action :set_contact

  reads_from_replica :index, max_lag: 10.seconds

  def index
    @inbox_members = @web_widget.inbox.inbox_members.includes(user: { avatar_attachment: :blob })
  end
end
