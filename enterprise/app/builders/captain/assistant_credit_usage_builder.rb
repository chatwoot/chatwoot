# Computes per-assistant credit consumption (from agent_sessions) for the
# Captain Overview page: window totals for the trend plus a per-day series for
# the usage chart.
#
# Days are bucketed on the viewer's calendar day, so a completed day's sum never
# changes. Those sums are cached per (assistant, timezone, date) with a long TTL
# and only the still-accruing current day is computed live on every request.
class Captain::AssistantCreditUsageBuilder
  CACHE_TTL = 30.days

  # Credit tracking on agent_sessions began on this date; there is no data
  # before it, so both spans are clamped to start here.
  DATA_EPOCH = Date.new(2026, 7, 17)

  def initialize(assistant, window)
    @assistant = assistant
    @window = window
  end

  # => { current:, previous:, daily: [{ date:, value: }, ...] }
  # `daily` covers the current window only; `previous` is the total for the
  # preceding equal-length day span, used for the trend.
  def build
    sums = daily_sums(previous_dates.to_a + current_dates.to_a)

    {
      current: total(sums, current_dates),
      previous: total(sums, previous_dates),
      daily: current_dates.map { |date| { date: date, value: sums[date] } }
    }
  end

  private

  attr_reader :assistant, :window

  # Credit usage is bucketed on calendar days (unlike the rolling timestamp
  # windows of the other metrics), so the previous span is derived from the
  # current one's dates rather than window.previous — this keeps the two spans
  # non-overlapping at the boundary day.
  def current_dates
    @current_dates ||= begin
      first = window.current.first.in_time_zone(timezone).to_date
      [first, DATA_EPOCH].max..window.current.last.in_time_zone(timezone).to_date
    end
  end

  # Clamping can leave this span empty (window fully before the epoch); the
  # trend then compares against 0 and the frontend hides it.
  def previous_dates
    first = current_dates.first - current_dates.count
    [first, DATA_EPOCH].max..(current_dates.first - 1)
  end

  def daily_sums(dates)
    cacheable = dates.select { |date| date < today }
    cached = Rails.cache.read_multi(*cacheable.map { |date| cache_key(date) })

    missing = dates.reject { |date| cached.key?(cache_key(date)) }
    live = live_sums(missing)
    missing.each do |date|
      Rails.cache.write(cache_key(date), live[date], expires_in: CACHE_TTL) if date < today
    end

    dates.index_with { |date| cached.fetch(cache_key(date)) { live[date] } }
  end

  # One grouped scan covering the span of the requested dates. Zero-filled via
  # groupdate so cache entries exist even for days without sessions.
  def live_sums(dates)
    return {} if dates.empty?

    span = dates.min.in_time_zone(timezone).beginning_of_day..dates.max.in_time_zone(timezone).end_of_day
    Captain::AgentSession
      .where(assistant_id: assistant.id, created_at: span)
      .group_by_day(:created_at, time_zone: timezone, range: span)
      .sum(:credits_consumed)
      .to_h { |day, value| [day.to_date, (value || 0).round(2)] }
  end

  def total(sums, dates)
    dates.sum { |date| sums[date] }.round(2)
  end

  def today
    @today ||= Time.current.in_time_zone(timezone).to_date
  end

  def timezone
    window.timezone
  end

  def cache_key(date)
    "captain_credit_usage/#{assistant.id}/#{timezone_name}/#{date}"
  end

  def timezone_name
    @timezone_name ||= timezone.is_a?(String) ? timezone : timezone.name
  end
end
