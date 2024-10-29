class SuperAdmin::DashboardController < SuperAdmin::ApplicationController
  include ActionView::Helpers::NumberHelper

  def index
    @data = Conversation.unscoped.group_by_day(:created_at, range: 30.days.ago..2.seconds.ago).count.to_a
    @accounts_count = number_with_delimiter(Account.count)
    @users_count = number_with_delimiter(User.count)
    @inboxes_count = number_with_delimiter(Inbox.count)
    @conversations_count = number_with_delimiter(Conversation.count)
  end
end
