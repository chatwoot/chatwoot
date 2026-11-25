# frozen_string_literal: true

module InboxBrandedEmailLayoutable
  extend ActiveSupport::Concern

  def branded_email_layout
    branded_email_layout_template&.body
  end

  def branded_email_layout_template
    email_templates.find_by(name: EmailTemplate::BRANDED_LAYOUT_NAME, template_type: :layout, locale: EmailTemplate::DEFAULT_LOCALE)
  end

  def effective_branded_email_layout_template(locale = I18n.locale)
    EmailTemplate.branded_layout_for(inbox: self, account: account, locale: locale)
  end

  def branded_email_layout_available?
    email? && account.feature_enabled?(:branded_email_templates) && effective_branded_email_layout_template.present?
  end

  def update_branded_email_layout!(body)
    if body.blank?
      branded_email_layout_template&.destroy!
      return
    end

    template = branded_email_layout_template || email_templates.new(
      name: EmailTemplate::BRANDED_LAYOUT_NAME,
      template_type: :layout,
      locale: EmailTemplate::DEFAULT_LOCALE,
      account: account
    )
    template.update!(body: body)
  end
end
