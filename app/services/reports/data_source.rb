class Reports::DataSource
  SUPPORTED_ROLLUP_DIMENSIONS = %w[account agent inbox].freeze

  attr_reader :account, :metric, :dimension_type, :dimension_id,
              :scope, :range, :group_by, :timezone,
              :timezone_offset, :business_hours

  class << self
    def for(**context)
      adapter_class_for(**context).new(**context)
    end

    def rollup_eligible?(**context)
      account = context[:account]

      rollup_enabled_for_account?(account) &&
        !hourly_grouping?(context[:group_by]) &&
        supported_dimension?(context[:dimension_type]) &&
        timezone_matches_account?(account, context[:timezone], context[:timezone_offset]) &&
        supported_metric?(context[:metric])
    end

    def timezone_matches_account?(account, timezone, timezone_offset)
      return normalized_timezone_identifier(timezone) == normalized_timezone_identifier(account.reporting_timezone) if timezone.present?

      return false if timezone_offset.blank?

      offset_in_seconds = timezone_offset.to_f * 3600
      account_zone = ActiveSupport::TimeZone[account.reporting_timezone]
      account_zone&.now&.utc_offset == offset_in_seconds
    end

    private

    def adapter_class_for(**context)
      rollup_eligible?(**context) ? Reports::RollupDataSource : Reports::RawDataSource
    end

    def rollup_enabled_for_account?(account)
      account.reporting_timezone.present? && account.feature_enabled?(:report_rollup)
    end

    def hourly_grouping?(group_by)
      group_by.to_s == 'hour'
    end

    def supported_dimension?(dimension_type)
      SUPPORTED_ROLLUP_DIMENSIONS.include?((dimension_type.presence || 'account').to_s)
    end

    def supported_metric?(metric)
      metric.blank? || Reports::ReportMetricRegistry.rollup_supported?(metric)
    end

    def normalized_timezone_identifier(timezone)
      ActiveSupport::TimeZone[timezone]&.tzinfo&.name
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
    @timezone = context[:timezone]
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

  def use_business_hours?
    ActiveModel::Type::Boolean.new.cast(business_hours)
  end
end
