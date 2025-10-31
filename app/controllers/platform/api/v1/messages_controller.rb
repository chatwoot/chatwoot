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
    # Send one email to all agents/administrators
    AgentNotifications::BookingMailer.booking_notification(
      agents: users,
      conversation: conversation,
      booking_date: params[:booking_date],
      phone: params[:phone],
      email: params[:email]
    ).deliver_now

    recipient_emails = users.map(&:email)
    Rails.logger.info("Booking email sent to #{users.size} recipients for conversation ##{conversation.id}")

    render json: {
      success: true,
      recipients: recipient_emails,
      total_sent: users.size
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
