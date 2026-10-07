class Api::V1::Accounts::BrandedEmailLayoutsController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?

  def show
    set_branded_email_layout
  end

  def update
    unless Current.account.feature_enabled?(:branded_email_templates)
      render_could_not_create_error('Branded email templates feature is not enabled')
      return
    end

    branded_email_layout = params[:branded_email_layout] == 'null' ? nil : params[:branded_email_layout]
    EmailTemplate.update_account_branded_layout!(account: Current.account, body: branded_email_layout) if params.key?(:branded_email_layout)
    set_branded_email_layout
  rescue ActiveRecord::RecordInvalid => e
    render_could_not_create_error(e.record.errors.full_messages.join(', '))
  end

  private

  def set_branded_email_layout
    @branded_email_layout = EmailTemplate.account_branded_layout_template_for(Current.account)&.body
  end
end

Api::V1::Accounts::BrandedEmailLayoutsController.prepend_mod_with('Api::V1::Accounts::BrandedEmailLayoutsController')
