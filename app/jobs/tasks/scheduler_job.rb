# frozen_string_literal: true

class Tasks::SchedulerJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Task.due_for_execution.find_each(batch_size: 100) do |task|
      Tasks::ExecutorJob.perform_later(task.id)
    end
  end
end
