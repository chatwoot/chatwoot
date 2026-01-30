class ApplicationMailer < ActionMailer::Base
  include ActionView::Helpers::SanitizeHelper

  default from: ENV.fetch('MAILER_SENDER_EMAIL', 'Julian at Cruise Control <support@getcruisecontrol.com>')
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
    Rails.logger.info "Email sent to #{args[0][:to]} with subject #{args[0][:subject]}"
    mail(*args) do |format|
      # explored sending a multipart email containing both text type and html
      # parsing the html with nokogiri will remove the links as well
      # might also remove tags like b,li etc. so lets rethink about this later
      # format.text { Nokogiri::HTML(render(layout: false)).text }
      format.html { render }
    end
  end

  # Helper method to generate conversation URL
  def conversation_url(conversation)
    "#{ENV.fetch('FRONTEND_URL',
                 nil)}/app/accounts/#{conversation.account_id}/inbox/#{conversation.inbox_id}/conversations/#{conversation.display_id}"
  end

  def instagram_profile_url(conversation)
    return unless conversation&.inbox&.channel_type == 'Channel::Instagram'

    contact = conversation.contact
    additional_attributes = contact.additional_attributes
    username =
      additional_attributes['social_instagram_user_name'].presence ||
      additional_attributes.dig('social_profiles', 'instagram').presence

    "https://www.instagram.com/#{username}"
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
    locals = {
      global_config: GlobalConfig.get('BRAND_NAME', 'BRAND_URL'),
      action_url: @action_url
    }

    locals[:attachment_url] = @attachment_url if defined?(@attachment_url) && @attachment_url
    locals[:failed_contacts] = @failed_contacts if defined?(@failed_contacts) && @failed_contacts
    locals[:imported_contacts] = @imported_contacts if defined?(@imported_contacts) && @imported_contacts
    locals[:instagram_profile_url] = @instagram_profile_url if defined?(@instagram_profile_url) && @instagram_profile_url.present?
    locals
  end

  def locale_from_account(account)
    return unless account

    I18n.available_locales.map(&:to_s).include?(account.locale) ? account.locale : nil
  end

  def ensure_current_account(account)
    Current.reset
    Current.account = account if account.present?
  end

  def switch_locale(&)
    locale ||= locale_from_account(Current.account)
    locale ||= I18n.default_locale
    # ensure locale won't bleed into other requests
    # https://guides.rubyonrails.org/i18n.html#managing-the-locale-across-requests
    I18n.with_locale(locale, &)
  end

  # Get SuperAdmin emails for a specific account - used when account is suspended
  # Returns only SuperAdmins who are associated with the given account
  def super_admin_emails(account)
    return [] unless account

    account.users.where(type: 'SuperAdmin').pluck(:email).compact
  end
end
