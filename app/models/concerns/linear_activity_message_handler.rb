module LinearActivityMessageHandler
  extend ActiveSupport::Concern

  def create_linear_issue_created_activity(issue_data)
    return unless issue_data[:id]

    content = I18n.t('conversations.activity.linear.issue_created', issue_id: issue_data[:id])
    ::Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content))
  end

  def create_linear_issue_linked_activity(issue_data)
    return unless issue_data[:id]

    content = I18n.t('conversations.activity.linear.issue_linked', issue_id: issue_data[:id])
    ::Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content))
  end

  def create_linear_issue_unlinked_activity(issue_data)
    return unless issue_data[:id]

    content = I18n.t('conversations.activity.linear.issue_unlinked', issue_id: issue_data[:id])
    ::Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content))
  end
end