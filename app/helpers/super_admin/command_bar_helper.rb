module SuperAdmin::CommandBarHelper
  def command_groups
    [
      { label: t('super_admin.command_bar.go_to'), commands: primary_nav_items },
      { label: t('super_admin.command_bar.create'), commands: create_commands },
      { label: t('super_admin.navigation.settings'), commands: settings_nav_items },
      { label: t('super_admin.navigation.monitor'), commands: monitor_nav_items },
      { label: t('super_admin.navigation.theme.label'), commands: theme_commands },
      { label: t('super_admin.navigation.account'), commands: session_commands }
    ]
  end

  def record_commands(record)
    commands = [
      { action: :show, label: t('super_admin.command_bar.open'), url: [namespace, record], icon: 'i-lucide-arrow-right' },
      { action: :edit, label: t('administrate.actions.edit'), url: [:edit, namespace, record], icon: 'i-lucide-pencil' }
    ].select { |command| accessible_action?(record, command[:action]) && !current_page?(command[:url]) }
    commands += user_commands(record) if record.is_a?(User)
    commands += account_commands(record) if record.is_a?(Account)
    return commands unless accessible_action?(record, :destroy)

    commands << { label: t('administrate.actions.destroy'), url: [namespace, record], method: :delete, icon: 'i-lucide-trash-2', danger: true,
                  form: { data: { confirm: t('administrate.actions.confirm') } } }
  end

  def result_commands(resource, records)
    commands = records.map do |record|
      { label: (record.try(:name) || record.try(:title)).presence || resource.singularize.titleize,
        hint: [record.try(:email), "##{record.id}"].compact.join(' · '),
        url: [namespace, record], icon: SuperAdmin::NavigationHelper::NAV_ICONS[resource],
        record_url: record_super_admin_command_bar_path(resource: resource, id: record.id) }
    end
    return commands if records.size < SuperAdmin::CommandBarsController::RESULTS_PER_RESOURCE

    commands << { label: t('super_admin.command_bar.see_all', resource: display_resource_name(resource).downcase),
                  url: url_for(controller: "/#{namespace}/#{resource}", action: :index, search: params[:q]), icon: 'i-lucide-list' }
  end

  private

  def create_commands
    nav_resources.select { |resource| existing_action?(resource, :new) }.map do |resource|
      { label: t('administrate.actions.new_resource', name: resource.singularize.titleize.downcase),
        url: [:new, namespace, resource.singularize.to_sym], icon: 'i-lucide-plus' }
    end
  end

  def theme_commands
    [
      { label: t('super_admin.navigation.theme.system'), icon: 'i-lucide-monitor', data: { theme_value: 'system' } },
      { label: t('super_admin.navigation.theme.light'), icon: 'i-lucide-sun', data: { theme_value: 'light' } },
      { label: t('super_admin.navigation.theme.dark'), icon: 'i-lucide-moon', data: { theme_value: 'dark' } }
    ]
  end

  def session_commands
    [
      { label: t('super_admin.navigation.profile'), url: super_admin_user_path(current_super_admin), icon: 'i-lucide-user' },
      { label: t('super_admin.navigation.agent_dashboard'), url: '/', icon: 'i-lucide-message-circle' },
      { label: t('super_admin.navigation.logout'), url: super_admin_logout_path, icon: 'i-lucide-log-out' }
    ]
  end

  def user_commands(user)
    commands = []
    if current_page?([namespace, user])
      commands << { label: t('super_admin.users.impersonate'), icon: 'i-lucide-venetian-mask', data: { dialog_open: 'impersonate-dialog' } }
    end
    return commands if user.confirmed?

    commands << { label: t('super_admin.users.resend_confirmation.button'), url: resend_confirmation_super_admin_user_path(user), method: :post,
                  icon: 'i-lucide-mail-check' }
  end

  def account_commands(account)
    commands = [{ label: t('super_admin.accounts.reset_cache'), url: reset_cache_super_admin_account_path(account), method: :post,
                  icon: 'i-lucide-refresh-cw' }]
    return commands unless Seeders::AccountSeeder.allowed?

    commands << { label: t('super_admin.accounts.seed_data'), url: seed_super_admin_account_path(account), method: :post, icon: 'i-lucide-sprout',
                  danger: true, form: { data: { confirm: t('super_admin.accounts.seed_data_warning') } } }
  end
end
