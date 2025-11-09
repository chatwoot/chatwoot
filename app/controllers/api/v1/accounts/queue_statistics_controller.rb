class Api::V1::Accounts::QueueStatisticsController < Api::V1::Accounts::BaseController
  def index
    @statistics = QueueStatistic
                  .where(account_id: Current.account.id)
                  .order(date: :desc)
                  .limit(30)
  end

  def show
    date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    @statistic = QueueStatistic.find_or_initialize_by(
      account_id: Current.account.id,
      date: date
    )
  end

  def current
    @queue_service = Queue::QueueService.new(account: Current.account)
    @current_queue_size = @queue_service.queue_size
    @statistic = QueueStatistic.find_or_initialize_by(
      account_id: Current.account.id,
      date: Date.current
    )
  end
end
