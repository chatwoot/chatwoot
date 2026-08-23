class Captain::Llm::PruneFailureLogsJob < ApplicationJob
  queue_as :housekeeping

  # A persistent LLM misconfiguration can flood the failure log (every chat turn,
  # embedding, or crawl attempt writes a row). Keep the table bounded for the
  # Super Admin debug panel so it stays fast and relevant.
  def perform(keep_count = 10_000)
    pruned = Captain::LlmFailureLog.prune!(keep_count: keep_count)
    Rails.logger.info("[Captain::Llm::PruneFailureLogsJob] pruned #{pruned} stale failure log rows")
  end
end
