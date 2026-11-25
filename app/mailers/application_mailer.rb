class ApplicationMailer < ActionMailer::Base
  include ActionView::Helpers::SanitizeHelper

  # Some mail is the installation's however an account got into Current. A credential reset
  # belongs to the person and not to one of their workspaces -- and the account it would pick
  # is whichever `accounts.first` returns, so a user in two workspaces would see one of them
  # at random on a password email. A compliance notice describes the installation itself.
  #
  # Per action, because a mailer can be both: Devise sends the password reset and the workspace
  # invitation, and the invitation names the account it invites into.
  class_attribute :installation_branded_actions, default: nil, instance_writer: false

  def self.installation_branded!(*actions)
    self.installation_branded_actions = actions.presence || :all
  end

  default from: ENV.fetch('MAILER_SENDER_EMAIL', 'Chatwoot <accounts@chatwoot.com>')
  around_action :with_isolated_current
  around_action :switch_locale
  layout 'mailer/base'
  # Fetch template from Database if available
  # Order: Account Specific > Installation Specific > Fallback to file
  prepend_view_path ::EmailTemplate.resolver
  append_view_path Rails.root.join('app/views/mailers')
  helper :frontend_urls
  # helper_method rather than a helper block: the block body runs in the view context, which
  # cannot reach the mailer instance that knows which brand applies.
  helper_method :global_config

  rescue_from(*ExceptionList::SMTP_EXCEPTIONS, with: :handle_smtp_exceptions)

  def liquid_filters
    [LiquidFilters::I18nFilter]
  end

  def smtp_config_set_or_development?
    ENV.fetch('SMTP_ADDRESS', nil).present? || ENV.fetch('RESEND_API_KEY', nil).present? || Rails.env.development?
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
      global_config: brand.config,
      # Two roles, because one hex cannot serve both: see BrandColor.
      brand_color: BrandColor.surface(brand.color),
      brand_color_text: BrandColor.on_light(brand.color),
      brand_logo_url: brand.logo_url,
      action_url: @action_url
    }

    locals.merge({ attachment_url: @attachment_url }) if @attachment_url
    locals.merge({ failed_contacts: @failed_contacts, imported_contacts: @imported_contacts })
    locals
  end

  def global_config
    @global_config ||= brand.config
  end

  def brand
    @brand ||= if installation_branded_action?
                 Brand.for
               else
                 Brand.for(account: Current.account, inbox: @conversation&.inbox)
               end
  end

  def installation_branded_action?
    actions = self.class.installation_branded_actions
    return false if actions.nil?
    return true if actions == :all

    actions.include?(action_name&.to_sym)
  end

  def locale_from_account(account)
    return unless account

    I18n.available_locales.map(&:to_s).include?(account.locale) ? account.locale : nil
  end

  # Current is thread-local and nothing downstream resets it, so a mailer that left the
  # account set would hand it to whatever ran next on the same thread -- the rest of an
  # automation rule inline, or the next Sidekiq job on that worker thread.
  def with_isolated_current
    Current.isolate do
      account = params.try(:[], :account)
      Current.account = account if account.present?
      yield
    end
  end

  def switch_locale(&)
    locale ||= locale_from_account(Current.account)
    locale ||= I18n.default_locale
    # ensure locale won't bleed into other requests
    # https://guides.rubyonrails.org/i18n.html#managing-the-locale-across-requests
    I18n.with_locale(locale, &)
  end
end
