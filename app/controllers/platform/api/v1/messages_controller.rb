class Platform::Api::V1::MessagesController < PlatformController
  def send_email_notification
    conversation = Conversation.find_by(id: params[:conversation_id])
    return render_error('Conversation not found', :not_found) unless conversation

    account = conversation.account
    agents = account.agents

    if agents.blank?
      Rails.logger.error("No agents assigned to account ##{account.id}")
      return render_error('No agents assigned', :unprocessable_entity)
    end

    if params[:booking_date].present?
      send_booking_notifications(conversation, agents)
    elsif params[:template_slug].present?
      send_template_notifications(conversation, agents)
    else
      Rails.logger.error("Required parameters missing for email notification")
      render_error('Either booking_date or template_slug must be provided', :bad_request)
    end
  rescue ActiveRecord::RecordNotFound => e
    render_error(e.message, :not_found)
  rescue StandardError => e
    Rails.logger.error("Error sending email notification: #{e.message}")
    render_error(e.message, :unprocessable_entity)
  end

  private

  def send_booking_notifications(conversation, agents)
    email_sent = false

    agents.each do |agent|
      begin
        AgentNotifications::BookingMailer.booking_notification(
          agent: agent,
          conversation: conversation,
          booking_date: params[:booking_date],
          phone: params[:phone],
          email: params[:email]
        ).deliver_now

        Rails.logger.info("Booking email sent to agent ##{agent.id} for conversation ##{conversation.id}")
        email_sent = true
      rescue => e
        Rails.logger.error("Failed to send booking email to agent ##{agent.id}: #{e.message}")
      end
    end

    if email_sent
      render json: { success: true }, status: :ok
    else
      render_error('Failed to send email to any agent', :internal_server_error)
    end
  end

  def send_template_notifications(conversation, agents)
    template = EmailTemplate.find_by(slug: params[:template_slug], account_id: conversation.account.id)

    return render_error('Template not found', :not_found) unless template

    agents.each do |agent|
      begin
        AgentNotifications::CustomMailer.notification_email(
          conversation,
          agent,
          template
        ).deliver_later

        Rails.logger.info("Notification email queued for agent ##{agent.id} for conversation ##{conversation.id}")
      rescue => e
        Rails.logger.error("Failed to queue notification email to agent ##{agent.id}: #{e.message}")
      end
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
