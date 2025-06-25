module LabelActivityMessageHandler
  extend ActiveSupport::Concern

  private

  def create_label_added(user_name, labels = [])
    create_label_change_activity('added', user_name, labels)
  end

  def create_label_removed(user_name, labels = [])
    create_label_change_activity('removed', user_name, labels)
  end

  def create_label_change_activity(change_type, user_name, labels = [])
    return unless labels.size.positive?

    content = I18n.t("conversations.activity.labels.#{change_type}", user_name: user_name, labels: labels.join(', '))
    ::Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content)) if content
  end
end
