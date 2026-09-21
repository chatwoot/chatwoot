class Copilot::V2::RunJob < ApplicationJob
  queue_as :default

  def perform(run_id)
    run = CopilotRun.find_by(id: run_id)
    Copilot::V2::Runner.new(run).call if run
  end
end
