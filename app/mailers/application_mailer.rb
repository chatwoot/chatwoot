# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  include ActionView::Helpers::SanitizeHelper

  # Make this URL helper available to mailer instances and views
  helper_method :app_account_conversation_url
  def app_account_conversation_url(account_id:, id:)
    base = ENV['FRONTEND_URL'] || 'http://127.0.0.1:3030'
    "#{base}/app/accounts/#{account_id}/conversations/#{id}"
  end

  default from: ENV.fetch('MAILER_SENDER_EMAIL', 'Chatwoot <accounts@chatwoot.com>')
  layout 'mailer/base'
  around_action :switch_locale

  # Optional: guard in case ExceptionList isn’t defined in your fork
  rescue_from(*ExceptionList::SMTP_EXCEPTIONS, with: :handle_smtp_exceptions) if defined?(ExceptionList::SMTP_EXCEPTIONS)

  def smtp_config_set_or_development?
    ENV['SMTP_ADDRESS'].present? || Rails.env.development?
  end

  private

  def switch_locale(&)
    I18n.with_locale(Current.account&.default_locale || I18n.default_locale, &)
  end

  def handle_smtp_exceptions(message)
    Rails.logger.warn 'Failed to send Email'
    Rails.logger.error "Exception: #{message}"
  end

  # Optional: used by some upstream templates
  def send_mail_with_liquid(*args)
    Rails.logger.info "Email sent to #{args[0][:to]} with subject #{args[0][:subject]}"
    mail(*args) { |format| format.html { render } }
  end

  def liquid_droppables
    { account: Current.account, user: @agent }
  end
end
