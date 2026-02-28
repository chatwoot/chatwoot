class Captain::Workflows::ExecutionJob < ApplicationJob
  queue_as :default

  def perform(workflow, context)
    Captain::Workflows::ExecutionService.new(workflow, context).perform
  end
end
