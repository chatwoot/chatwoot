class EmailTemplates::AdvancedTemplateResolver
  # Added template_type to arguments
  def initialize(user:, template_name:, account:, template_type:)
    @user = user
    @template_name = template_name
    @account = account
    @template_type = template_type
  end

  def perform
    # Check priorities in order: User -> Account -> Global -> nil
    find_user_template || find_account_template || find_global_template
  end

  private

  def find_user_template
    # 1. Priority: Check User's Active Template
    return unless @user

    active_user_template = @user.user_assignments
                                .joins(:advanced_email_template)
                                .where(active: true)
                                .where(advanced_email_templates: {
                                         name: @template_name,
                                         template_type: @template_type
                                       })
                                .first
                                &.advanced_email_template

    formatted_result(active_user_template, 'user_active') if active_user_template
  end

  def find_account_template
    # 2. Priority: Check Account Default
    return unless @account

    account_template = @account.account_email_templates.find_by(
      name: @template_name,
      template_type: @template_type
    )
    formatted_result(account_template, 'account_default') if account_template
  end

  def find_global_template
    # 3. Priority: Check Global Fallback
    global_template = GlobalEmailTemplate.find_by(
      name: @template_name,
      template_type: @template_type
    )
    formatted_result(global_template, 'global_fallback') if global_template

    # 4. Fallback: Return nil if nothing is found (Implicit return)
  end

  def formatted_result(template, source)
    {
      template: template,
      source: source,
      html: template.html,
      type: template.template_type
    }
  end
end
