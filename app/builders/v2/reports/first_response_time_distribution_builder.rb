class V2::Reports::FirstResponseTimeDistributionBuilder
  include DateRangeHelper

  attr_reader :account, :params

  def initialize(account:, params:)
    @account = account
    @params = params
  end

  def build
    build_distribution
  end

  private

  def build_distribution
    results = fetch_aggregated_counts
    format_results(results)
  end

  def fetch_aggregated_counts
    ReportingEvent
      .joins('INNER JOIN inboxes ON reporting_events.inbox_id = inboxes.id')
      .where(account_id: account.id, name: 'first_response')
      .where(range_condition)
      .group('inboxes.channel_type')
      .select(
        'inboxes.channel_type',
        bucket_case_statements
      )
  end

  def bucket_case_statements
    <<~SQL.squish
      COUNT(CASE WHEN reporting_events.value < 3600 THEN 1 END) AS bucket_0_1h,
      COUNT(CASE WHEN reporting_events.value >= 3600 AND reporting_events.value < 14400 THEN 1 END) AS bucket_1_4h,
      COUNT(CASE WHEN reporting_events.value >= 14400 AND reporting_events.value < 28800 THEN 1 END) AS bucket_4_8h,
      COUNT(CASE WHEN reporting_events.value >= 28800 AND reporting_events.value < 86400 THEN 1 END) AS bucket_8_24h,
      COUNT(CASE WHEN reporting_events.value >= 86400 THEN 1 END) AS bucket_24h_plus
    SQL
  end

  def range_condition
    range.present? ? { created_at: range } : {}
  end

  def format_results(results)
    results.each_with_object({}) do |row, hash|
      hash[row.channel_type] = {
        '0-1h' => row.bucket_0_1h,
        '1-4h' => row.bucket_1_4h,
        '4-8h' => row.bucket_4_8h,
        '8-24h' => row.bucket_8_24h,
        '24h+' => row.bucket_24h_plus
      }
    end
  end
end
