class ApplicationMailer < ActionMailer::Base
  include ActionView::Helpers::SanitizeHelper

  default from: ENV.fetch('MAILER_SENDER_EMAIL', 'Chatwoot <accounts@chatwoot.com>')
  before_action { ensure_current_account(params.try(:[], :account)) }
  around_action :switch_locale
  layout 'mailer/base'
  # Fetch template from Database if available
  # Order: Account Specific > Installation Specific > Fallback to file
  prepend_view_path ::EmailTemplate.resolver
  append_view_path Rails.root.join('app/views/mailers')
  helper :frontend_urls
  helper do
    def global_config
      @global_config ||= GlobalConfig.get('BRAND_NAME', 'BRAND_URL')
    end
  end

  rescue_from(*ExceptionList::SMTP_EXCEPTIONS, with: :handle_smtp_exceptions)

  def smtp_config_set_or_development?
    ENV.fetch('SMTP_ADDRESS', nil).present? || Rails.env.development?
  end

  private

  def handle_smtp_exceptions(message)
    Rails.logger.warn 'Failed to send Email'
    Rails.logger.error "Exception: #{message}"
  end

  def send_mail_with_liquid(*args)
    mail(*args) do |format|
      # explored sending a multipart email containing both text type and html
      # parsing the html with nokogiri will remove the links as well
      # might also remove tags like b,li etc. so lets rethink about this later
      # format.text { Nokogiri::HTML(render(layout: false)).text }
      format.html { render }
    end
  end

  def liquid_droppables
    # Merge additional objects into this in your mailer
    # liquid template handler converts these objects into drop objects
    {
      account: Current.account,
      user: @agent,
      conversation: @conversation,
      inbox: @conversation&.inbox
    }
  end

  def liquid_locals
    # expose variables you want to be exposed in liquid
    {
      global_config: GlobalConfig.get('BRAND_NAME', 'BRAND_URL'),
      action_url: @action_url
    }
  end

  def locale_from_account(account)
    return unless account

    I18n.available_locales.map(&:to_s).include?(account.locale) ? account.locale : nil
  end

  def ensure_current_account(account)
    Current.reset
    Current.account = account if account.present?
  end

  def switch_locale(&action)
    locale ||= locale_from_account(Current.account)
    locale ||= I18n.default_locale
    # ensure locale won't bleed into other requests
    # https://guides.rubyonrails.org/i18n.html#managing-the-locale-across-requests
    I18n.with_locale(locale, &action)
  end
end
