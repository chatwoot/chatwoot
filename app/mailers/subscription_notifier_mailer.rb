class SubscriptionNotifierMailer < ApplicationMailer
  def mau_limit_warning(user, current_mau, limit)
    @user = user
    @current_mau = current_mau
    @limit = limit

    mail(
      to: @user.email,
      subject: "Warning: MAU Limit Nearing (#{@current_mau}/#{@limit})"
    )
  end
end
