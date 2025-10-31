class Platform::Api::V1::MessagesController < PlatformController
  def send_email_notification
    conversation = Conversation.find_by(id: params[:conversation_id])
    return render_error('Conversation not found', :not_found) unless conversation

    account = conversation.account
    users = get_notification_recipients(account)

    if users.blank?
      Rails.logger.error("No users to notify for account ##{account.id}")
      return render_error('No agents or administrators found', :unprocessable_entity)
    end

    if params[:booking_date].present?
      send_booking_notifications(conversation, users)
    elsif params[:template_slug].present?
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

  def get_notification_recipients(account)
    # Get all agents and administrators, then deduplicate by user
    agents = account.agents
    administrators = account.users.where(account_users: { role: :administrator })

    # Combine and deduplicate by user ID to avoid sending duplicate emails
    (agents + administrators).uniq
  end

  def send_booking_notifications(conversation, users)
    email_sent = false
    failed_count = 0
    successful_recipients = []

    users.each do |user|
      AgentNotifications::BookingMailer.booking_notification(
        agent: user,
        conversation: conversation,
        booking_date: params[:booking_date],
        phone: params[:phone],
        email: params[:email]
      ).deliver_now

      Rails.logger.info("Booking email sent to user ##{user.id} (#{user.email}) for conversation ##{conversation.id}")
      email_sent = true
      successful_recipients << user.email
    rescue StandardError => e
      Rails.logger.error("Failed to send booking email to user ##{user.id} (#{user.email}): #{e.message}")
      failed_count += 1
    end

    # Send SMS notifications
    Sms::BookingNotificationService.new(
      conversation: conversation,
      booking_date: params[:booking_date],
      phone: params[:phone],
      email: params[:email]
    ).perform

    if email_sent
      render json: {
        success: true,
        recipients: successful_recipients,
        total_sent: successful_recipients.size,
        total_failed: failed_count
      }, status: :ok
    else
      render_error('Failed to send email to any user', :internal_server_error)
    end
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
