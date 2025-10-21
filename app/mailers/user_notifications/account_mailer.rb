module UserNotifications
  class AccountMailer < ApplicationMailer
    def welcome_with_password(user, password)
      return unless smtp_config_set_or_development?

      @user = user
      @password = password
      subject = 'Welcome to AlooChat - Your Account Details'
      @action_url = "#{ENV.fetch('FRONTEND_URL', "https://cx.aloochat.ai")}/app/login"

      send_mail_with_liquid(to: @user.email, subject: subject)
    end

    def welcome_to_aloostudio_with_password(user, password)
      return unless smtp_config_set_or_development?

      @user = user
      @password = password
      subject = 'Welcome to AlooStudio - Your Account Details'
      @action_url = "#{ENV.fetch('ALOOSTUDIO_FRONTEND_URL', 'https://studio.aloochat.ai')}"

      send_mail_with_liquid(to: @user.email, subject: subject)
    end

    private

    def liquid_droppables
      super.merge({
                    user: @user,
                    password: @password
                  })
    end
  end
end
