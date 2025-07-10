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

  def upcoming_expiry(email, account_id, payment_date, customer_name, nama_paket, tanggal_expired_paket)
    @account_id = account_id
    @payment_date = payment_date
    @customer_name = customer_name
    @nama_paket = nama_paket
    @tanggal_expired_paket = tanggal_expired_paket

    mail(
      to: email,
      subject: "⏰ Paket Anda akan berakhir dalam 7 hari – Yuk, perpanjang sekarang!"
    )
  end
end
