class ApplicationMailer < ActionMailer::Base
  include ActionView::Helpers::SanitizeHelper

  default from: ENV.fetch('MAILER_SENDER_EMAIL', 'accounts@chatwoot.com')
  before_action { Current.account = params[:account] }
  layout 'mailer/base'
  # Fetch template from Database if available
  # Order: Account Specific > Installation Specific > Fallback to file
  prepend_view_path ::EmailTemplate.resolver
  append_view_path Rails.root.join('app/views/mailers')

  # Helpers
  helper :frontend_urls
  helper do
    def global_config
      @global_config ||= GlobalConfig.get('INSTALLATION_NAME', 'BRAND_URL')
    end
  end

  def smtp_config_set_or_development?
    ENV.fetch('SMTP_ADDRESS', nil).present? || Rails.env.development?
  end

  def ensure_current_account(account)
    Current.account = account
  end

  private

  def send_mail_with_liquid(*args)
    with_layout = render_to_string
    with_out_layout = strip_tags(render_to_string(layout: false))

    @text_email = Liquid::Template.parse(with_out_layout)
    @html_email = Liquid::Template.parse(with_layout)
    assign_drops

    mail(*args) do |format|
      format.text { render body: @text_email.render, layout: false }
      format.html { render body: @html_email.render, layout: false }
    end
  end

  def droppables
    # Merge additional objects into this in your mailer
    { account: Current.account }
  end

  def assign_drops
    droppables.each do |key, obj|
      @text_email.assigns[key.to_s] = obj.to_drop
      @html_email.assigns[key.to_s] = obj.to_drop
    end
  end
end
