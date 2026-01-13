# frozen_string_literal: true

require 'gruff'

module Reports
  class MonthlyPieChart
    def self.generate(conversations_by_channel)
      return nil if conversations_by_channel.blank? || conversations_by_channel.values.sum.zero?

      g = Gruff::Pie.new(840)
      g.title = 'Monthly Impact Breakdown'
      g.theme = {
        colors: %w[#1f93ff #22c55e #f97316 #ef4444 #8b5cf6 #ec4899 #14b8a6 #f59e0b],
        marker_color: '#6b7280',
        font_color: '#111827',
        background_colors: %w[#ffffff #ffffff]
      }

      conversations_by_channel.each do |channel_name, count|
        g.data("#{channel_name} (#{count})", count) if count.positive?
      end

      path = Rails.root.join(
        'tmp',
        "monthly_impact_#{SecureRandom.uuid}.png"
      )

      g.write(path.to_s)
      path.to_s
    rescue StandardError => e
      Rails.logger.error "MonthlyPieChart generation failed: #{e.class} - #{e.message}"
      nil
    end
  end
end