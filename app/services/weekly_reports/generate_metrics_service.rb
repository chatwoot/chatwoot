class WeeklyReports::GenerateMetricsService
  def initialize(account, start_date, end_date)
    @account = account
    @start_date = start_date
    @end_date = end_date
    @dealership_id = account.dealership_id
  end

  def perform
    conversations = @account.conversations.where(created_at: @start_date..@end_date)

    api_stats = fetch_booking_stats_from_api

    {
      new_conversations: conversations.count,
      booking_links_sent: api_stats[:booking_links_sent],
      booking_forms_completed: api_stats[:booking_forms_completed],
      conversion_rate: api_stats[:conversion_rate],
      estimated_value: api_stats[:estimated_value],
      dealership_name: @account.name
    }
  end

  private

  def fetch_booking_stats_from_api
    return empty_stats unless @dealership_id.present?

    api = Dealership::BookingStatsService.new(
      @dealership_id,
      period: 'weekly',
      since: @start_date,
      until_time: @end_date
    )

    result = api.fetch_stats

    # Correct location of weekly stats
    weekly_data = result[:data]
    return empty_stats unless weekly_data.is_a?(Array) && weekly_data.any?

    expected_week = "#{@start_date.strftime('%d-%b')}-#{@end_date.strftime('%d-%b')}"
    Rails.logger.info "Looking for week: #{expected_week}"

    # Find matching week or fallback to latest
    row = weekly_data.find { |r| r['week'] == expected_week } || weekly_data.last
    return empty_stats unless row.present?

    booking = row.dig('booking_type_breakdown', 'booking')
    return empty_stats unless booking.present?

    links_sent = booking['links_sent'].to_i
    forms_completed = booking['forms_completed'].to_i

    conversion_rate =
      links_sent > 0 ? ((forms_completed * 100) / links_sent).round : 0

    estimated_value = forms_completed * 250

    {
      booking_links_sent: links_sent,
      booking_forms_completed: forms_completed,
      conversion_rate: conversion_rate,
      estimated_value: estimated_value
    }
  rescue StandardError => e
    Rails.logger.error("Weekly Report API Error: #{e.message}")
    empty_stats
  end

  def empty_stats
    {
      booking_links_sent: 0,
      booking_forms_completed: 0,
      conversion_rate: 0,
      estimated_value: 0
    }
  end
end
