class Platform::Api::V1::MessagesController < PlatformController
    
    def send_email_notification
      conversation = Conversation.find_by(id: params[:conversation_id])
      return render json: { error: 'Conversation not found' }, status: :not_found unless conversation
  
      account = conversation.account
      template = EmailTemplate.find_by(slug: params[:template_slug], account_id: account.id)
      return render json: { error: 'Template not found' }, status: :not_found unless template
  
      recipients = User.joins(:account_users)
                       .where(account_users: { account_id: account.id, role: 'agent' })
                       .compact
  
      recipients.each do |agent|
        next if agent.nil?
        AgentNotifications::CustomMailer.notification_email(
          conversation,
          agent,
          template
        ).deliver_later
      end
  
      render json: {
        status: 'success',
        message: 'Email notifications sent successfully',
        recipients: recipients.map(&:email)
      }
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: e.message }, status: :not_found
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end 