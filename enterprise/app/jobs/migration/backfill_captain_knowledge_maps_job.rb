class Migration::BackfillCaptainKnowledgeMapsJob < ApplicationJob
  queue_as :low

  def perform
    assistants_with_knowledge.find_each do |assistant|
      Captain::KnowledgeMapBuilderJob.perform_later(assistant.id)
    end
  end

  private

  def assistants_with_knowledge
    Captain::Assistant
      .joins(:responses)
      .merge(Captain::AssistantResponse.approved)
      .distinct
  end
end
