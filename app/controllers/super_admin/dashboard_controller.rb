class SuperAdmin::DashboardController < SuperAdmin::ApplicationController
  include ActionView::Helpers::NumberHelper

  def index
    @data = Conversation.unscoped.group_by_day(:created_at, range: 30.days.ago..2.seconds.ago).count.to_a
    @accounts_count = number_with_delimiter(Account.all.length)
    @users_count = number_with_delimiter(User.all.length)
    @inboxes_count = number_with_delimiter(Inbox.all.length)
    @conversations_count = number_with_delimiter(Conversation.all.length)
    @messages_count = number_with_delimiter(Message.all.length)
  end
end
