# frozen_string_literal: true

class Saas::BillingMailer < ApplicationMailer
  default from: ENV.fetch('MAILER_SENDER_EMAIL', 'AirysChat <noreply@airyschat.com>')

  def welcome(account)
    return unless smtp_config_set_or_development?

    @account = account
    @admin = account.administrators.first
    return unless @admin

    @plan = account.saas_plan
    @billing_url = billing_url(account)
    @dashboard_url = dashboard_url(account)
    @reset_password_url = build_reset_password_url(account)

    subject = I18n.t('saas.mailer.welcome.subject')
    mail(to: @admin.email, subject: subject)
  end

  def trial_expiring(account)
    return unless smtp_config_set_or_development?

    @account = account
    @admin = account.administrators.first
    return unless @admin

    subscription = account.saas_subscription
    return unless subscription&.trial_end

    @days_left = [(subscription.trial_end.to_date - Date.current).to_i, 0].max
    @billing_url = billing_url(account)

    subject = I18n.t('saas.mailer.trial_expiring.subject', days: @days_left)
    mail(to: @admin.email, subject: subject)
  end

  def payment_failed(account, attempt_count = 1)
    return unless smtp_config_set_or_development?

    @account = account
    @admin = account.administrators.first
    return unless @admin

    @attempt_count = attempt_count
    @is_final_warning = attempt_count >= 3
    @billing_url = billing_url(account)

    subject = I18n.t('saas.mailer.payment_failed.subject')
    mail(to: @admin.email, subject: subject)
  end

  def usage_alert(account, percentage)
    return unless smtp_config_set_or_development?

    @account = account
    @admin = account.administrators.first
    return unless @admin

    @percentage = percentage
    @plan = account.saas_plan
    @tokens_used = account.ai_monthly_usage
    @tokens_limit = @plan&.ai_tokens_monthly || 0
    @billing_url = billing_url(account)

    subject = I18n.t('saas.mailer.usage_alert.subject', percentage: percentage)
    mail(to: @admin.email, subject: subject)
  end

  def subscription_canceled(account)
    return unless smtp_config_set_or_development?

    @account = account
    @admin = account.administrators.first
    return unless @admin

    @billing_url = billing_url(account)

    subject = I18n.t('saas.mailer.subscription_canceled.subject')
    mail(to: @admin.email, subject: subject)
  end

  def plan_changed(account, old_plan_name, new_plan_name)
    return unless smtp_config_set_or_development?

    @account = account
    @admin = account.administrators.first
    return unless @admin

    @old_plan_name = old_plan_name
    @new_plan_name = new_plan_name
    @plan = account.saas_plan
    @billing_url = billing_url(account)

    subject = I18n.t('saas.mailer.plan_changed.subject', plan: new_plan_name)
    mail(to: @admin.email, subject: subject)
  end

  private

  def liquid_locals
    super.merge(
      billing_url: @billing_url,
      dashboard_url: @dashboard_url,
      reset_password_url: @reset_password_url,
      admin_name: @admin&.name,
      plan_name: @plan&.name || 'Free',
      old_plan_name: @old_plan_name,
      new_plan_name: @new_plan_name,
      days_left: @days_left,
      attempt_count: @attempt_count,
      is_final_warning: @is_final_warning,
      percentage: @percentage,
      tokens_used: @tokens_used,
      tokens_limit: @tokens_limit
    )
  end

  def billing_url(account)
    "#{ENV.fetch('FRONTEND_URL', '')}/app/accounts/#{account.id}/settings/billing"
  end

  def dashboard_url(account)
    "#{ENV.fetch('FRONTEND_URL', '')}/app/accounts/#{account.id}/dashboard"
  end

  def build_reset_password_url(account)
    token = account.custom_attributes&.dig('reset_token')
    return nil unless token

    "#{ENV.fetch('FRONTEND_URL', '')}/app/auth/password/edit?reset_password_token=#{token}"
  end
end
