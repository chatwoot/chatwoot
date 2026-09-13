class Captain::AproposTurnJob < ApplicationJob
  queue_as :default

  def perform(session_id)
    Captain::Apropos::TurnService.new(Captain::AproposSession.find(session_id)).perform
  end
end
