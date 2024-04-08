module Enterprise::AgentNotifications::ConversationNotificationsMailer
  def missed_slas_digest(user, missed_slas)
    return unless smtp_config_set_or_development?

    @user = user
    @missed_slas = missed_slas
    subject = 'Missed SLAs Digest'

    # Group missed SLAs by conversation using each_with_object
    @missed_slas_by_conversation = @missed_slas.each_with_object({}) do |missed_sla, result|
      applied_sla = missed_sla[:applied_sla]
      sla_events = missed_sla[:sla_events]
      conversation = applied_sla.conversation

      result[conversation] ||= []
      result[conversation] << {
        sla_events: sla_events,
        applied_sla: applied_sla
      }
    end

    send_mail_with_liquid(to: @user.email, subject: subject) and return
  end

  def liquid_droppables
    super.merge({
                  missed_slas_by_conversation: @missed_slas_by_conversation
                })
  end
end
