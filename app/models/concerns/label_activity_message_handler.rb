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

    params = activity_message_params("labels.#{change_type}", user_name: user_name, labels: labels.join(', '), **activity_actor_params)
    ::Conversations::ActivityMessageJob.perform_later(self, params)
  end
end
