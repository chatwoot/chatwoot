class Reports::DataSource
  include TimezoneHelper

  attr_reader :account, :metric, :dimension_type, :dimension_id,
              :scope, :range, :group_by, :timezone_offset,
              :business_hours

  class << self
    def for(**context)
      # TODO: Route to Reports::RollupDataSource when rollup reads are implemented
      Reports::RawDataSource.new(**context)
    end
  end

  def initialize(**context)
    @account = context[:account]
    @metric = context[:metric]
    @dimension_type = (context[:dimension_type].presence || 'account').to_s
    @dimension_id = context[:dimension_id]
    @scope = context[:scope]
    @range = context[:range]
    @group_by = context[:group_by].to_s.presence || 'day'
    @timezone_offset = context[:timezone_offset]
    @business_hours = context[:business_hours]
  end

  private

  def report_metric
    @report_metric ||= Reports::ReportMetricRegistry.fetch(metric)
  end

  def average_metric?
    report_metric&.average?
  end

  def count_metric?
    !average_metric?
  end

  def rollup_metric
    report_metric&.rollup_metric
  end

  def raw_event_name
    report_metric&.raw_event_name
  end

  def raw_count_strategy
    report_metric&.raw_count_strategy
  end

  def summary_metrics
    @summary_metrics ||= Reports::ReportMetricRegistry.summary_metrics
  end

  def timezone
    @timezone ||= timezone_name_from_offset(timezone_offset)
  end

  def use_business_hours?
    ActiveModel::Type::Boolean.new.cast(business_hours)
  end
end
