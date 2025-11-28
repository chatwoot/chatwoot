class Platform::Api::V1::MessagesController < PlatformController
  def send_email_notification
    conversation = Conversation.find_by(id: params[:conversation_id])
    return render_error('Conversation not found', :not_found) unless conversation

    account = conversation.account

    if params[:booking_date].present?
      emails = get_booking_emails(account)
      return if validate_recipients_presence(emails, 'booking emails', account)

      send_booking_notifications(conversation, emails)

    elsif params[:template_slug].present?
      users = get_template_users(account)
      return if validate_recipients_presence(users, 'agents or administrators', account)

      send_template_notifications(conversation, users)

    else
      Rails.logger.error('Required parameters missing for email notification')
      render_error('Either booking_date or template_slug must be provided', :bad_request)
    end
  rescue ActiveRecord::RecordNotFound => e
    render_error(e.message, :not_found)
  rescue StandardError => e
    Rails.logger.error("Error sending email notification: #{e.message}")
    render_error(e.message, :unprocessable_entity)
  end

  private

  def validate_recipients_presence(recipients, recipient_type, account)
    return false if recipients.present?

    Rails.logger.error("No #{recipient_type} found for account ##{account.id}")
    render_error("No #{recipient_type} configured", :unprocessable_entity)
    true
  end

  def get_booking_emails(account)
    account.booking_emails.presence || []
  end

  def get_template_users(account)
    agents = account.agents
    administrators = account.users.where(account_users: { role: :administrator })
    (agents + administrators).uniq
  end

  def send_booking_notifications(conversation, emails)
    AgentNotifications::BookingMailer.booking_notification(
      emails: emails,
      conversation: conversation,
      booking_date: params[:booking_date],
      phone: params[:phone],
      email: params[:email]
    ).deliver_now

    Rails.logger.info("Booking email sent to #{emails.size} recipients for conversation ##{conversation.id}")

    Sms::BookingNotificationService.new(
      conversation: conversation,
      booking_date: params[:booking_date],
      phone: params[:phone],
      email: params[:email]
    ).perform

    render json: {
      success: true,
      recipients: emails,
      total_sent: emails.size
    }, status: :ok
  rescue StandardError => e
    Rails.logger.error("Failed to send booking notifications: #{e.message}")
    render_error('Failed to send booking notifications', :internal_server_error)
  end

  def send_template_notifications(conversation, agents)
    template = EmailTemplate.find_by(slug: params[:template_slug], account_id: conversation.account.id)

    return render_error('Template not found', :not_found) unless template

    agents.each do |agent|
      AgentNotifications::CustomMailer.notification_email(
        conversation,
        agent,
        template
      ).deliver_later

      Rails.logger.info("Notification email queued for agent ##{agent.id} for conversation ##{conversation.id}")
    rescue StandardError => e
      Rails.logger.error("Failed to queue notification email to agent ##{agent.id}: #{e.message}")
    end

    render json: {
      success: true,
      message: 'Email notifications sent successfully',
      recipients: agents.map(&:email)
    }, status: :ok
  end

  def render_error(message, status)
    render json: { success: false, error: message }, status: status
  end
end
