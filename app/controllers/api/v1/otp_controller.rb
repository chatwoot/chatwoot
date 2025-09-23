class Api::V1::OtpController < Api::BaseController
  skip_before_action :authenticate_access_token!, only: [:generate, :verify, :resend, :status]
  skip_before_action :authenticate_user!, only: [:generate, :verify, :resend, :status]
  skip_before_action :validate_bot_access_token!, only: [:generate, :verify, :resend, :status]

  def status
    Rails.logger.info "OTP Status check for email: #{params[:email]}"
    
    user = User.find_by(email: params[:email])

    if user.blank?
      Rails.logger.warn "User not found for email: #{params[:email]}"
      return render json: { error: 'User not found' }, status: :not_found
    end

    if user.confirmed?
      return render json: { 
        status: 'verified',
        message: 'Email already verified' 
      }, status: :ok
    end

    # Check if there's an active OTP
    otp = user.otps.where(purpose: 'email_verification')
                  .where('expires_at > ?', Time.current)
                  .order(created_at: :desc)
                  .first

    if otp.present?
      render json: { 
        status: 'otp_active',
        message: 'OTP is active and ready for verification',
        expires_at: otp.expires_at,
        expires_in: ((otp.expires_at - Time.current) / 60).round(0)
      }, status: :ok
    else
      render json: { 
        status: 'otp_needed',
        message: 'No active OTP found. Please generate a new OTP.'
      }, status: :ok
    end
  rescue StandardError => e
    Rails.logger.error "Error in OTP status check: #{e.class}: #{e.message}"
    render json: { error: 'An error occurred while checking OTP status' }, status: :internal_server_error
  end

  def generate
    Rails.logger.info "OTP Generate request for email: #{params[:email]}"
    
    user = User.find_by(email: params[:email])

    if user.blank?
      Rails.logger.warn "User not found for email: #{params[:email]}"
      return render json: { error: 'User not found' }, status: :not_found
    end

    Rails.logger.info "User found: #{user.id}, confirmed: #{user.confirmed?}"

    if user.confirmed?
      return render json: { error: 'Email already verified' }, status: :unprocessable_entity
    end

    # Check if there's already an active OTP
    existing_otp = user.otps.where(purpose: 'email_verification')
                           .where('expires_at > ?', Time.current)
                           .order(created_at: :desc)
                           .first

    if existing_otp.present?
      Rails.logger.info "Active OTP already exists for user: #{user.id}, expires at: #{existing_otp.expires_at}"
      return render json: { 
        message: 'OTP already sent and still active',
        expires_at: existing_otp.expires_at,
        expires_in: ((existing_otp.expires_at - Time.current) / 60).round(0),
        resend_available: false
      }, status: :ok
    end

    # Generate OTP for email verification
    Rails.logger.info "Generating OTP for user: #{user.id}"
    otp = user.generate_otp('email_verification', 5, request)
    Rails.logger.info "OTP generated: #{otp.present? ? 'success' : 'failed'}"

    if otp
      # Send OTP email
      Rails.logger.info "Sending OTP email to: #{user.email}"
      OtpMailer.send_otp_email(user, otp).deliver_now
      Rails.logger.info "OTP email sent successfully"
      
      render json: { 
        message: 'OTP sent successfully',
        expires_at: otp.expires_at
      }, status: :ok
    else
      Rails.logger.error "Failed to generate OTP for user: #{user.id}"
      render json: { error: 'Failed to generate OTP' }, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "Error in OTP generate: #{e.class}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: 'An error occurred while generating OTP' }, status: :internal_server_error
  end

  def verify
    user = User.find_by(email: params[:email])

    if user.blank?
      return render json: { error: 'User not found' }, status: :not_found
    end

    if user.confirmed?
      return render json: { error: 'Email already verified' }, status: :unprocessable_entity
    end

    Rails.logger.info "OTP verification request for user: #{user.email}"
    result = user.verify_otp(params[:code], 'email_verification')

    if result[:success]
      Rails.logger.info "OTP verification successful for user: #{user.email}"
      
      # Check if user needs account creation (new registration flow)
      if user.custom_attributes&.dig('registration_completed') == false
        Rails.logger.info "Completing account creation for user: #{user.email}"
        
        begin
          # Get pending account details
          account_name = user.custom_attributes['pending_account_name'] || 'My Account'
          locale = user.custom_attributes['pending_locale'] || I18n.locale
          
          # Create account
          account = Account.create!(
            name: account_name,
            locale: locale
          )
          
          # Link user to account as administrator
          AccountUser.create!(
            account_id: account.id,
            user_id: user.id,
            role: AccountUser.roles['administrator']
          )
          
          # Assign Free Trial subscription
          assign_free_trial_subscription(account)
          
          # Mark registration as completed and clear pending data
          user.update!(
            custom_attributes: user.custom_attributes.merge(
              'registration_completed' => true
            ).except('pending_account_name', 'pending_locale')
          )
          
          Rails.logger.info "Account #{account.id} created and user #{user.id} linked successfully"
          
          # Send verification success email
          begin
            OtpMailer.send_verification_success_email(user, account).deliver_now
            Rails.logger.info "Verification success email sent to #{user.email}"
          rescue => email_error
            Rails.logger.error "Failed to send verification success email: #{email_error.message}"
          end
          
          render json: { 
            message: 'Email verified and account created successfully. You can now log in.',
            verified: true,
            account_created: true,
            next_step: 'login',
            redirect_url: ENV.fetch('FRONTEND_URL', 'http://localhost:3000') + '/app/login'
          }, status: :ok
        rescue => e
          Rails.logger.error "Failed to create account for user #{user.id}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          render json: { 
            message: 'Email verified but failed to create account. Please contact support.',
            verified: true,
            account_created: false,
            error: e.message
          }, status: :unprocessable_entity
        end
      else
        # User already has account or this is just email verification
        # Send verification success email
        begin
          # Get user's first account for the email
          account = user.accounts.first
          OtpMailer.send_verification_success_email(user, account).deliver_now
          Rails.logger.info "Verification success email sent to #{user.email}"
        rescue => email_error
          Rails.logger.error "Failed to send verification success email: #{email_error.message}"
        end
        
        render json: { 
          message: 'Email verified successfully',
          verified: true
        }, status: :ok
      end
    else
      Rails.logger.warn "OTP verification failed for user: #{user.email}, error: #{result[:error]}"
      render json: { 
        error: result[:error] || 'Invalid or expired OTP'
      }, status: :unprocessable_entity
    end
  rescue StandardError => e
    render json: { error: 'An error occurred while verifying OTP' }, status: :internal_server_error
  end

  def resend
    user = User.find_by(email: params[:email])

    if user.blank?
      return render json: { error: 'User not found' }, status: :not_found
    end

    if user.confirmed?
      return render json: { error: 'Email already verified' }, status: :unprocessable_entity
    end

    # Check for recent OTP generation (cooldown: 1 minute)
    recent_otp = user.otps.where(purpose: 'email_verification')
                          .where('created_at > ?', 1.minute.ago)
                          .order(created_at: :desc)
                          .first

    if recent_otp.present?
      time_remaining = 60 - (Time.current - recent_otp.created_at).to_i
      return render json: { 
        error: 'Please wait before requesting a new OTP',
        retry_after_seconds: time_remaining,
        message: "You can request a new OTP in #{time_remaining} seconds"
      }, status: :too_many_requests
    end

    # Generate new OTP (this will invalidate old ones)
    otp = user.generate_otp('email_verification', 5, request)

    if otp
      # Send OTP email
      OtpMailer.send_otp_email(user, otp).deliver_now
      Rails.logger.info "OTP resent successfully to #{user.email}"
      render json: { 
        message: 'OTP resent successfully',
        expires_at: otp.expires_at
      }, status: :ok
    else
      render json: { error: 'Failed to resend OTP' }, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "Error in OTP resend: #{e.class}: #{e.message}"
    render json: { error: 'An error occurred while resending OTP' }, status: :internal_server_error
  end

  private

  def otp_params
    params.permit(:email, :code)
  end

  def assign_free_trial_subscription(account)
    free_trial_plan = SubscriptionPlan.find_by(name: 'Free Trial')

    Rails.logger.info "Free Trial Plan: #{free_trial_plan.inspect}"
    
    if free_trial_plan.present?
      # Create a new subscription for the account
      subscription = Subscription.create!(
        account_id: account.id,
        plan_name: free_trial_plan.name,
        max_mau: free_trial_plan.max_mau,
        max_ai_agents: free_trial_plan.max_ai_agents,
        max_ai_responses: free_trial_plan.max_ai_responses,
        max_human_agents: free_trial_plan.max_human_agents,
        max_channels: free_trial_plan.max_channels,
        available_channels: free_trial_plan.available_channels,
        support_level: free_trial_plan.support_level,
        subscription_plan_id: free_trial_plan.id,
        status: 'active',
        starts_at: Time.current,
        ends_at: Time.current + free_trial_plan.duration_days.days,
        amount_paid: free_trial_plan.monthly_price,
        price: free_trial_plan.monthly_price,
        payment_status: "paid"
      )

      # Update account.active_subscription_id
      account.update!(active_subscription_id: subscription.id)
      Rails.logger.info "Free Trial Subscription created: #{subscription.id}"
    else
      Rails.logger.warn "Free Trial plan not found"
    end
  rescue StandardError => e
    Rails.logger.error "Error creating subscription: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end