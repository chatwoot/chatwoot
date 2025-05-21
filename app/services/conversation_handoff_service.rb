class ConversationHandoffService
  HANDOFF_COOLDOWN_MINUTES = 240 # 4 hours in minutes
  HANDOFF_LABEL = %w[handoff].freeze
  LABELS_LIST = %w[handoff stark].freeze

  def initialize(conversation)
    @conversation = conversation
  end

  def process_handoff
    return unless should_send_notification?

    ensure_labels_exist
    update_handoff_state
    schedule_label_change

    ConversationHandoff::SendHandoffNotificationsJob.perform_later(@conversation)
  end

  private

  def should_send_notification?
    return true if @conversation.last_handoff_at.nil?

    minutes_since_last_handoff = ((Time.current - @conversation.last_handoff_at) / 1.minute).round
    minutes_since_last_handoff >= HANDOFF_COOLDOWN_MINUTES
  end

  def ensure_labels_exist
    LABELS_LIST.each do |label_title|
      Label.find_or_create_by!(account: @conversation.account, title: label_title) do |label|
        label.show_on_sidebar = true
        label.color = '#1f93ff'
      end
    end
  end

  def update_handoff_state
    conversation_labels = @conversation.label_list.to_a

    @conversation.update_labels(conversation_labels - ['stark']) if @conversation.label_list.include?('stark')
    current_handoff_label = conversation_labels.find { |label| HANDOFF_LABEL.include?(label) }
    available_label = current_handoff_label || HANDOFF_LABEL.first

    @conversation.add_labels(HANDOFF_LABEL) unless @conversation.label_list.include?(available_label)
    @conversation.update_columns(last_handoff_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
  end

  def schedule_label_change
    ScheduleHandoffLabelChangeJob.set(wait: HANDOFF_COOLDOWN_MINUTES.minutes)
                                 .perform_later(@conversation)
  end
end
