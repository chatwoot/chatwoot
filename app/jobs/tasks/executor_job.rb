# frozen_string_literal: true

class Tasks::ExecutorJob < ApplicationJob
  queue_as :default

  def perform(task_id)
    task = Task.find_by(id: task_id)
    return unless task&.pending?

    task.update!(status: :in_progress)
    execute(task)
    task.update!(status: :completed)
  rescue StandardError => e
    Rails.logger.error("Tasks::ExecutorJob failed for task #{task_id}: #{e.message}")
    task&.update(status: :cancelled)
  end

  private

  def execute(task)
    case task.action_type
    when 'send_message'        then Tasks::Executors::SendMessageExecutor.new(task).call
    when 'assign_conversation' then Tasks::Executors::AssignConversationExecutor.new(task).call
    when 'schedule_appointment' then Tasks::Executors::ScheduleAppointmentExecutor.new(task).call
    end
  end
end
