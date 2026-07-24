# frozen_string_literal: true

class Automations::TimeBasedSchedulerJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    AutomationRule.active.where(event_name: 'time_triggered').find_each do |rule|
      Automations::TimeBasedRuleRunner.new(rule).perform
    end
  end
end
