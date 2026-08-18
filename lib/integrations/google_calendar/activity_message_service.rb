class Integrations::GoogleCalendar::ActivityMessageService
  def initialize(conversation:, action_type:, user:, event_data: {})
    @conversation = conversation
    @action_type = action_type
    @user = user
    @event_data = event_data
  end

  def perform
    return unless conversation && user

    content = generate_activity_content
    return if content.blank?

    Conversations::ActivityMessageJob.perform_later(conversation, activity_message_params(content))
  end

  private

  attr_reader :conversation, :action_type, :user, :event_data

  def generate_activity_content
    I18n.t(
      "conversations.activity.calendar.#{action_type}",
      user_name: user.name,
      event_title: event_data[:summary]
    )
  rescue I18n::MissingTranslationData
    nil
  end

  def activity_message_params(content)
    {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :activity,
      content: content
    }
  end
end
