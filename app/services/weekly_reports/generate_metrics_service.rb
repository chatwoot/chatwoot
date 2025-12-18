class WeeklyReports::GenerateMetricsService
  def initialize(account, start_date, end_date)
    @account = account
    @start_date = start_date.beginning_of_day
    @end_date = end_date.end_of_day
    @dealership_id = account.dealership_id
  end

  def perform
    conversations = @account.conversations.where(created_at: @start_date..@end_date)
    incoming_messages = @account.messages.incoming.where(created_at: @start_date..@end_date).count
    outgoing_messages = @account.messages.outgoing.where(created_at: @start_date..@end_date).count

    api_stats = fetch_booking_stats_from_api

    {
      new_conversations: conversations.count,
      total_messages: incoming_messages + outgoing_messages,
      booking_links_sent: api_stats[:booking_links_sent],
      booking_forms_completed: api_stats[:booking_forms_completed],
      handoff_links_sent: api_stats[:handoff_links_sent],
      handoff_forms_completed: api_stats[:handoff_forms_completed],
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
      period: 'daily',
      since: @start_date,
      until_time: @end_date
    )

    result = api.fetch_stats
    daily_data = result[:data]
    return empty_stats unless daily_data.is_a?(Array) && daily_data.any?

    links_sent = 0
    forms_completed = 0
    handoff_links_sent = 0
    handoff_forms_completed = 0

    daily_data.each do |day_stats|
      date_str = day_stats['date']
      next unless date_str.present?

      date = Date.parse(date_str)
      next unless date >= @start_date && date <= @end_date

      booking = day_stats.dig('booking_type_breakdown', 'booking')
      handoff = day_stats.dig('booking_type_breakdown', 'handoff')

      if booking.present?
        links_sent += booking['links_sent'].to_i
        forms_completed += booking['forms_completed'].to_i
      end

      if handoff.present?
        handoff_links_sent += handoff['links_sent'].to_i
        handoff_forms_completed += handoff['forms_completed'].to_i
      end
    end

    conversion_rate =
      links_sent > 0 ? ((forms_completed * 100) / links_sent).round : 0

    estimated_value = forms_completed * 250

    {
      booking_links_sent: links_sent,
      booking_forms_completed: forms_completed,
      handoff_links_sent: handoff_links_sent,
      handoff_forms_completed: handoff_forms_completed,
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
      handoff_links_sent: 0,
      handoff_forms_completed: 0,
      conversion_rate: 0,
      estimated_value: 0
    }
  end
end
