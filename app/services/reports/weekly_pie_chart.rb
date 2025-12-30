# frozen_string_literal: true

require 'gruff'

module Reports
  class WeeklyPieChart
    def self.generate(metrics)
      values = {
        'New Conversations' => metrics[:new_conversations].to_i,
        'Total Messages' => metrics[:total_messages].to_i,
        'CRM Leads' => metrics[:booking_forms_completed].to_i,
        'Handoff Requests' => metrics[:handoff_forms_completed].to_i
      }

      return nil if values.values.sum.zero?

      g = Gruff::Pie.new(420)
      g.title = 'Weekly Impact Breakdown'
      g.theme = {
        colors: %w[#1f93ff #22c55e #f97316 #ef4444],
        marker_color: '#6b7280',
        font_color: '#111827',
        # Gruff expects two background colors for gradient; use solid white
        background_colors: %w[#ffffff #ffffff]
      }

      values.each do |label, value|
        g.data(label, value) if value.positive?
      end

      path = Rails.root.join(
        'tmp',
        "weekly_impact_#{SecureRandom.uuid}.png"
      )

      g.write(path.to_s)
      path.to_s
    rescue StandardError => e
      Rails.logger.error "WeeklyPieChart generation failed: #{e.class} - #{e.message}"
      nil
    end
  end
end