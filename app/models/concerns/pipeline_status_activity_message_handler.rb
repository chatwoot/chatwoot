module PipelineStatusActivityMessageHandler
  extend ActiveSupport::Concern

  private

  def pipeline_status_change_activity(user_name)
    return unless saved_change_to_pipeline_status_id?

    user_name = activity_message_owner(user_name)
    return unless user_name

    status_name = pipeline_status&.name || I18n.t('conversations.activity.pipeline_status.unknown')
    content = I18n.t('conversations.activity.pipeline_status.updated', user_name: user_name, status_name: status_name)

    ::Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content)) if content
  end
end
