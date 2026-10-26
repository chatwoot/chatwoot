# Reviews and actions post their progress to the thread after each batch, so the agent can follow a run that takes
# minutes. Each class writes its own progress_text.
module Concerns::CopilotRunProgress
  extend ActiveSupport::Concern

  def publish_progress
    progress = summary
    return if copilot_thread.copilot_messages.assistant_thinking.last&.message&.dig('progress') == progress.as_json

    copilot_thread.copilot_messages.create!(message_type: :assistant_thinking, message: { content: progress_text(progress), progress: progress })
  end
end
