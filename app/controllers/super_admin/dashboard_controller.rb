class SuperAdmin::DashboardController < SuperAdmin::ApplicationController
  def index
    @data = Message.unscoped.group_by_day(:created_at, range: 30.days.ago..2.seconds.ago).count.to_a
  end
end
