module ConversationMonitors::ConversationTracking
  extend ActiveSupport::Concern

  included do
    before_destroy :invalidate_monitor_reports
    after_destroy_commit :refresh_monitor_reports
  end

  private

  def invalidate_monitor_reports
    work = ConversationMonitors::WorkItem.find_by(conversation_id: id)
    return unless work

    # Match the evaluator's lock order before cascading the work and memberships.
    work.with_lock do
      @affected_monitor_ids = ConversationMonitors::Evaluation.where(conversation_id: id).order(:monitor_id).pluck(:monitor_id)
      ConversationMonitors::Monitor.where(id: @affected_monitor_ids).order(:id).each do |monitor|
        monitor.with_lock { monitor.update!(data_revision: monitor.data_revision + 1) }
      end
    end
  end

  def refresh_monitor_reports
    Array(@affected_monitor_ids).each { |monitor_id| ConversationMonitors::BroadcastJob.schedule(monitor_id) }
  end
end
