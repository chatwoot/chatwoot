class Voice::RingingTimeoutJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Voice::RingingTimeoutService.overdue.find_each do |call|
      Voice::RingingTimeoutService.new(call: call).perform
    end
  end
end
