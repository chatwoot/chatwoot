class Captain::KnowledgeMapBuilderJob < MutexApplicationJob
  queue_as :low

  LOCK_TIMEOUT = 15.minutes
  REBUILD_DELAY = 1.minute

  retry_on_lock_conflict wait: 30.seconds, attempts: 30
  retry_on Captain::Llm::KnowledgeMapGenerationError, wait: 1.minute, attempts: 3

  def perform(assistant_id)
    assistant = Captain::Assistant.find_by(id: assistant_id)
    return unless assistant

    with_lock(lock_key(assistant), LOCK_TIMEOUT) do
      rebuild(assistant)
    end
  end

  private

  def rebuild(assistant)
    service = Captain::Llm::KnowledgeMapService.new(assistant: assistant)
    source_digest = service.source_digest
    return if assistant.knowledge_map_source_digest == source_digest

    result = service.perform
    return schedule_rebuild(assistant) if knowledge_changed?(assistant, source_digest)

    assistant.update!(
      knowledge_map: result.fetch(:message),
      knowledge_map_source_digest: source_digest,
      knowledge_map_built_at: Time.current
    )
  end

  def knowledge_changed?(assistant, source_digest)
    latest_service = Captain::Llm::KnowledgeMapService.new(assistant: assistant.reload)
    latest_service.source_digest != source_digest
  end

  def schedule_rebuild(assistant)
    self.class.set(wait: REBUILD_DELAY).perform_later(assistant.id)
  end

  def lock_key(assistant)
    format(::Redis::Alfred::CAPTAIN_KNOWLEDGE_MAP_MUTEX, assistant_id: assistant.id)
  end
end
