module Synapseos
  class DashboardSummaryService
    def initialize(account, period_days: 30)
      @account = account
      @period_days = period_days
      @range = period_days.days.ago.beginning_of_day..Time.current
    end

    def call
      {
        period_days: @period_days,
        period_start: @range.first,
        period_end: @range.last,
        kpis: kpis,
        daily: daily_breakdown,
      }
    end

    private

    def kpis
      {
        leads: leads_scope.count,
        deals_won: won_deals.count,
        deals_lost: lost_deals.count,
        revenue: won_deals.sum(:amount).to_f,
        messages_received: messages.where(message_type: :incoming).count,
        messages_sent: messages.where(message_type: :outgoing).count,
        bot_takeovers: events_of('bot_takeover').count,
        human_rescues: events_of('human_rescue').count,
        ai_responses: messages.where(sender_type: 'AgentBot').count,
        appointments: events_of('appointment_confirmed').count,
        conversion_rate: conversion_rate,
      }
    end

    def daily_breakdown
      days = (0...@period_days).map { |offset| (@period_days - 1 - offset).days.ago.to_date }
      msgs_in = messages.where(message_type: :incoming).reorder(nil).group("DATE(created_at)").count
      msgs_out = messages.where(message_type: :outgoing).reorder(nil).group("DATE(created_at)").count
      takeovers = events_of('bot_takeover').reorder(nil).group("DATE(created_at)").count
      ai_resp = messages.where(sender_type: 'AgentBot').reorder(nil).group("DATE(created_at)").count

      days.map do |day|
        {
          date: day.iso8601,
          messages_received: msgs_in[day].to_i,
          messages_sent: msgs_out[day].to_i,
          bot_takeovers: takeovers[day].to_i,
          ai_responses: ai_resp[day].to_i,
        }
      end
    end

    def leads_scope
      ::Synapseos::Lead.where(account_id: @account.id, created_at: @range)
    end

    def deals_scope
      ::Synapseos::Deal.where(account_id: @account.id)
    end

    def won_deals
      deals_scope.where(status: ::Synapseos::Deal.statuses[:won], closed_at: @range)
    end

    def lost_deals
      deals_scope.where(status: ::Synapseos::Deal.statuses[:lost], closed_at: @range)
    end

    def messages
      ::Message.where(account_id: @account.id, created_at: @range)
    end

    def events_of(type)
      ::Synapseos::CrmEvent.where(account_id: @account.id, event_type: type, created_at: @range)
    end

    def conversion_rate
      total_leads = leads_scope.count
      return 0.0 if total_leads.zero?

      ((won_deals.count.to_f / total_leads) * 100).round(2)
    end
  end
end
