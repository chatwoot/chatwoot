class V2::Reports::BaseSummaryBuilder
  include DateRangeHelper

  private

  def group_by_key
    # Override this method
  end

  def get_grouped_average(events)
    events.group(group_by_key).average(average_value_key)
  end

  def average_value_key
    params[:business_hours].present? ? :value_in_business_hours : :value
  end
end
