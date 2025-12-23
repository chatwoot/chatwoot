# frozen_string_literal: true

module ISPSupport
  # Tool for escalating complex issues to human support agents.
  class EscalateToHumanTool < Agents::Tool
    description "Escalate the issue to a human support agent"

    def perform(_tool_context)
      "I'm connecting you to a human support agent. Please hold while I transfer your case. A live agent will be with you shortly to provide personalized assistance."
    end
  end
end
