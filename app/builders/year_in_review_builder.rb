class YearInReviewBuilder
  attr_reader :account, :user_id, :year

  def initialize(account:, user_id:, year:)
    @account = account
    @user_id = user_id
    @year = year
  end

  def build
    {
      year: year,
      total_conversations: total_conversations_count,
      busiest_day: busiest_day_data,
      support_personality: support_personality_data
    }
  end

  private

  def year_range
    @year_range ||= begin
      start_time = Time.zone.local(year, 1, 1).beginning_of_day
      end_time = Time.zone.local(year, 12, 31).end_of_day
      start_time..end_time
    end
  end

  def total_conversations_count
    account.conversations
           .where(assignee_id: user_id, created_at: year_range)
           .count
  end

  def busiest_day_data
    daily_counts = account.conversations
                          .where(assignee_id: user_id, created_at: year_range)
                          .group_by_day(:created_at, range: year_range, time_zone: Time.zone)
                          .count

    return nil if daily_counts.empty?

    busiest_date, count = daily_counts.max_by { |_date, cnt| cnt }

    return nil if count.zero?

    {
      date: busiest_date.strftime('%b %d'),
      count: count
    }
  end

  def support_personality_data
    response_time = average_response_time

    return { avg_response_time_seconds: 0 } if response_time.nil?

    {
      avg_response_time_seconds: response_time.to_i
    }
  end

  def average_response_time
    avg_time = account.reporting_events
                      .where(
                        name: 'first_response',
                        user_id: user_id,
                        created_at: year_range
                      )
                      .average(:value)

    avg_time&.to_f
  end
end
