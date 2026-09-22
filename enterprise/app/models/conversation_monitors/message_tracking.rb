module ConversationMonitors::MessageTracking
  extend ActiveSupport::Concern

  included do
    after_create :request_monitor_evaluation
    after_update :invalidate_monitor_evaluation, if: :monitor_content_changed?
    before_destroy :invalidate_monitor_evaluation, unless: :private?
    after_create_commit :catch_up_monitor_activation
    after_commit :wake_monitor_evaluation
  end

  private

  def request_monitor_evaluation
    return unless (incoming? || outgoing?) && !private?

    @monitor_work_requested = ConversationMonitors::Scheduler.request(conversation, activity_at: created_at).present?
    @monitor_creation_tracked = @monitor_work_requested
  end

  def catch_up_monitor_activation
    # A monitor can be activated after this message's transaction began.
    return if @monitor_creation_tracked

    request_monitor_evaluation
    wake_monitor_evaluation
  end

  def invalidate_monitor_evaluation
    return if activity? || template?
    return if conversation.nil?

    @monitor_work_requested = ConversationMonitors::Scheduler.request(conversation, invalidate: true).present?
    @monitor_content_invalidated = @monitor_work_requested
  end

  def monitor_content_changed?
    return false if private? && !saved_change_to_private?

    saved_change_to_content? || saved_change_to_private? || saved_change_to_content_type? || monitor_deletion_changed?
  end

  def monitor_deletion_changed?
    saved_change_to_content_attributes? && content_attributes_before_last_save&.dig('deleted') != content_attributes['deleted']
  end

  def wake_monitor_evaluation
    return unless @monitor_work_requested

    @monitor_work_requested = false
    ConversationMonitors::Scheduler.wake(conversation_id)
    return unless @monitor_content_invalidated

    @monitor_content_invalidated = false
    ConversationMonitors::Evaluation.where(conversation_id: conversation_id).pluck(:monitor_id).each do |monitor_id|
      ConversationMonitors::BroadcastJob.schedule(monitor_id)
    end
  end
end
