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
    map_to_channel_types(results)
  end

  def fetch_aggregated_counts
    ReportingEvent
      .where(account_id: account.id, name: 'first_response')
      .where(range_condition)
      .group(:inbox_id)
      .select(
        :inbox_id,
        bucket_case_statements
      )
  end

  def bucket_case_statements
    <<~SQL.squish
      COUNT(CASE WHEN value < 3600 THEN 1 END) AS bucket_0_1h,
      COUNT(CASE WHEN value >= 3600 AND value < 14400 THEN 1 END) AS bucket_1_4h,
      COUNT(CASE WHEN value >= 14400 AND value < 28800 THEN 1 END) AS bucket_4_8h,
      COUNT(CASE WHEN value >= 28800 AND value < 86400 THEN 1 END) AS bucket_8_24h,
      COUNT(CASE WHEN value >= 86400 THEN 1 END) AS bucket_24h_plus
    SQL
  end

  def range_condition
    range.present? ? { created_at: range } : {}
  end

  def inbox_channel_types
    @inbox_channel_types ||= account.inboxes.pluck(:id, :channel_type).to_h
  end

  def map_to_channel_types(results)
    results.each_with_object({}) do |row, hash|
      channel_type = inbox_channel_types[row.inbox_id]
      next unless channel_type

      hash[channel_type] ||= empty_buckets
      hash[channel_type]['0-1h'] += row.bucket_0_1h
      hash[channel_type]['1-4h'] += row.bucket_1_4h
      hash[channel_type]['4-8h'] += row.bucket_4_8h
      hash[channel_type]['8-24h'] += row.bucket_8_24h
      hash[channel_type]['24h+'] += row.bucket_24h_plus
    end
  end

  def empty_buckets
    { '0-1h' => 0, '1-4h' => 0, '4-8h' => 0, '8-24h' => 0, '24h+' => 0 }
  end
end
