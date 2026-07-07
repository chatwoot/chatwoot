# Resolves the current and previous comparison windows for Captain assistant
# stats. `range` is either a day count ('7', '30', '90') or a named period
# ('this_month', 'last_month'). The previous window mirrors the current one: the
# preceding N days for day ranges, or the preceding month for month ranges.
# `timezone_offset` is the viewer's UTC offset in hours (as the reports API sends
# it), so month/day boundaries anchor to the viewer's day rather than UTC.
#
# Shared by Captain::AssistantStatsBuilder (which needs both windows) and
# Captain::AssistantDrilldownBuilder (which drills into the current window), so a
# drilldown always covers exactly the rows its stat card counted.
class Captain::AssistantStatsWindow
  include TimezoneHelper

  DEFAULT_RANGE = '30'.freeze
  ALLOWED_RANGES = %w[7 30 90 this_month last_month].freeze

  attr_reader :range

  def initialize(range = DEFAULT_RANGE, timezone_offset = nil)
    @range = ALLOWED_RANGES.include?(range.to_s) ? range.to_s : DEFAULT_RANGE
    @timezone = timezone_name_from_offset(timezone_offset) || Time.zone
  end

  def current
    resolved_ranges[:current]
  end

  def previous
    resolved_ranges[:previous]
  end

  # Human-readable description of the period the current window covers, for
  # grounding the LLM summary in real dates.
  def period
    { label: period_label, starts_on: current.first.to_date, ends_on: current.last.to_date }
  end

  private

  def resolved_ranges
    @resolved_ranges ||= case range
                         when 'this_month' then this_month_ranges
                         when 'last_month' then last_month_ranges
                         else day_ranges
                         end
  end

  # Current time anchored to the viewer's timezone, so calendar boundaries land on
  # the viewer's day instead of UTC's.
  def now
    @now ||= Time.current.in_time_zone(@timezone)
  end

  def this_month_ranges
    start = now.beginning_of_month
    elapsed = now - start
    previous_start = start - 1.month
    # Clamp to the previous month's end so a longer current month can't pull the
    # comparison window into the current month and double-count its rows.
    previous_end = [previous_start + elapsed, previous_start.end_of_month].min
    { current: start..now, previous: previous_start..previous_end }
  end

  def last_month_ranges
    start = (now - 1.month).beginning_of_month
    previous_start = start - 1.month
    { current: start..start.end_of_month, previous: previous_start..previous_start.end_of_month }
  end

  def day_ranges
    days = range.to_i
    { current: (now - days.days)..now, previous: (now - (2 * days).days)..(now - days.days) }
  end

  def period_label
    { 'this_month' => 'this month', 'last_month' => 'last month' }[range] || "the last #{range.to_i} days"
  end
end
