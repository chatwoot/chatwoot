class SuperAdmin::EmailLayoutsController < SuperAdmin::EnterpriseBaseController
  before_action :set_account
  before_action :set_custom_templates
  before_action :set_template_selection
  before_action :set_email_layout
  before_action :ensure_custom_branding_access!

  def edit
    @show_template_editor = editor_requested?
    return unless @show_template_editor

    @layout_body = @email_layout&.body || inherited_template_body
    set_preview_context
  end

  def update
    @layout_body = layout_params[:body].to_s
    validation_error = validate_layout_body(@layout_body)

    return render_edit_with_alert(validation_error) if validation_error.present?

    return render_edit_with_alert(conflict_error) if conflicting_template_exists?

    @email_layout ||= EmailTemplate.new(name: template_name, template_type: template_type, locale: template_locale, account: @account)
    @email_layout.body = @layout_body

    if @email_layout.save
      # rubocop:disable Rails/I18nLocaleTexts
      redirect_to edit_email_layout_path, notice: 'Email layout updated successfully'
      # rubocop:enable Rails/I18nLocaleTexts
    else
      render_edit_with_alert(@email_layout.errors.full_messages.join(', '))
    end
  end

  def destroy
    @email_layout&.destroy
    redirect_to email_layout_overview_path, notice: reset_notice
  end

  private

  def set_account
    @account = Account.find(params[:account_id]) if params[:account_id].present?
  end

  def set_custom_templates
    @custom_templates = EmailTemplate.where(account: @account).order(:template_type, :name, :locale)
  end

  def set_template_selection
    @template_type = selected_template_type
    @template_name = selected_template_name
    @template_locale = selected_template_locale
    @template_options = template_options
    @locale_options = locale_options
  end

  def set_email_layout
    @email_layout = EmailTemplate.find_by(name: template_name, template_type: template_type, locale: template_locale, account: @account)
  end

  attr_reader :template_name, :template_type, :template_locale

  def default_layout_body
    Rails.root.join('app/views/layouts/mailer/base.liquid').read
  end

  def default_content_body
    content_template_path.read
  end

  def inherited_template_body
    return global_template_body || default_template_body if @account.present?

    default_template_body
  end

  def default_template_body
    return default_layout_body if template_type == 'layout'

    default_content_body
  end

  def global_template_body
    EmailTemplate.find_by(name: template_name, template_type: template_type, locale: template_locale, account: nil)&.body
  end

  def layout_params
    params.require(:email_layout).permit(:body, :template_type, :template_name, :locale)
  end

  def validate_layout_body(body)
    return 'Template body cannot be blank' if body.blank?
    return 'Layout must include {{ content_for_layout }}' if template_type == 'layout' && !body.match?(/\{\{\s*content_for_layout\s*\}\}/)

    Liquid::Template.parse(body)
    nil
  rescue Liquid::SyntaxError => e
    "Liquid syntax error: #{e.message}"
  end

  def render_edit_with_alert(message)
    flash.now[:alert] = message
    @show_template_editor = true
    set_preview_context
    render :edit, status: :unprocessable_entity
  end

  def set_preview_context
    @preview_html = render_preview(@layout_body)
    @supported_variables = supported_variables
    @template_status = template_status
    @preview_config = preview_config
  rescue Liquid::SyntaxError
    @preview_html = ''
    @supported_variables = supported_variables
    @template_status = template_status
    @preview_config = preview_config
  end

  def render_preview(body)
    assigns = {
      'content_for_layout' => preview_content,
      'global_config' => GlobalConfig.get('BRAND_NAME', 'BRAND_URL')
    }
    assigns['account'] = { 'name' => @account.name } if @account.present?

    rendered_body = Liquid::Template.parse(body).render(assigns)
    return rendered_body if template_type == 'layout'

    Liquid::Template.parse(default_layout_body).render(assigns.merge('content_for_layout' => rendered_body))
  end

  def preview_content
    <<~HTML
      <tr>
        <td style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; padding: 0;">
          <h1 style="font-size: 20px; margin: 0 0 12px;">Sample notification</h1>
          <p style="margin: 0 0 16px;">This preview shows how notification content renders inside your email layout.</p>
          <a href="#" style="display: inline-block; background: #1f93ff; color: #fff; padding: 10px 14px; border-radius: 6px; text-decoration: none;">View conversation</a>
        </td>
      </tr>
    HTML
  end

  def preview_config
    brand_config = GlobalConfig.get('BRAND_NAME', 'BRAND_URL')
    {
      templateType: template_type,
      defaultLayout: default_layout_body,
      previewContent: preview_content,
      brandName: brand_config['BRAND_NAME'].to_s,
      brandUrl: brand_config['BRAND_URL'].to_s,
      accountName: @account&.name.to_s
    }
  end

  def supported_variables
    variables = []
    if template_type == 'layout'
      variables << {
        variable: '{{ content_for_layout }}',
        description: 'Required. Renders the email body inside the layout.'
      }
    end

    variables + [
      {
        variable: "{{ global_config['BRAND_NAME'] }}",
        description: 'Current brand name from Custom Branding.'
      },
      {
        variable: "{{ global_config['BRAND_URL'] }}",
        description: 'Current brand URL from Custom Branding.'
      }
    ].tap do |template_variables|
      next if @account.blank?

      template_variables << {
        variable: '{{ account.name }}',
        description: 'Current account name for account-specific previews.'
      }
    end
  end

  def conflict_error
    "Cannot save template. '#{template_name}' is already used by another email template for this account, type, and language."
  end

  def conflicting_template_exists?
    return false if @email_layout.present?

    EmailTemplate.exists?(name: template_name, template_type: template_type, locale: template_locale, account: @account)
  end

  def edit_email_layout_path
    query = { template_type: template_type, template_name: template_name, locale: template_locale }
    return edit_super_admin_account_email_layout_path(@account, query) if @account.present?

    edit_super_admin_email_layout_path(query)
  end

  def email_layout_overview_path
    return edit_super_admin_account_email_layout_path(@account) if @account.present?

    edit_super_admin_email_layout_path
  end

  def editor_requested?
    params[:new].present? || params[:template_type].present? || params[:template_name].present? || params[:locale].present?
  end

  def reset_notice
    return 'Account email template reset to inherited template' if @account.present?

    'Email template reset to default'
  end

  def ensure_custom_branding_access!
    return if ChatwootHub.pricing_plan != 'community'

    invalid_action_perfomed
  end

  def selected_template_type
    selected_type = params.dig(:email_layout, :template_type).presence || params[:template_type].presence || 'layout'
    EmailTemplate.template_types.key?(selected_type) ? selected_type : 'layout'
  end

  def selected_template_name
    selected_name = params.dig(:email_layout, :template_name).presence || params[:template_name].presence
    selected_name = default_template_name if selected_name.blank?
    available_template_names.include?(selected_name) ? selected_name : default_template_name
  end

  def selected_template_locale
    selected_locale = params.dig(:email_layout, :locale).presence || params[:locale].presence || 'en'
    EmailTemplate.locales.key?(selected_locale) ? selected_locale : 'en'
  end

  def default_template_name
    return 'base' if template_type == 'layout'

    content_template_options.first[:name]
  end

  def template_options
    return [{ name: 'base', label: 'Base layout' }] if template_type == 'layout'

    content_template_options
  end

  def available_template_names
    template_options.pluck(:name)
  end

  def content_template_options
    @content_template_options ||= Rails.root.glob('app/views/mailers/**/*.liquid').map do |path|
      name = path.relative_path_from(Rails.root.join('app/views/mailers')).to_s.delete_suffix('.liquid')
      { name: name, label: name.humanize }
    end.sort_by { |template| template[:label] }
  end

  def content_template_path
    Rails.root.join('app/views/mailers', "#{template_name}.liquid")
  end

  def locale_options
    EmailTemplate.locales.keys.map { |locale| [locale.upcase, locale] }
  end

  def template_status
    return 'Account override configured' if @account.present? && @email_layout.present?
    return 'Global override configured' if @account.blank? && @email_layout.present?
    return 'Inherits global template' if @account.present? && global_template_body.present?

    'Inherits default template'
  end
end
