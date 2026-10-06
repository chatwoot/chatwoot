module SuperAdmin::NavigationHelper
  NAV_ICONS = {
    'accounts' => 'i-lucide-building-2',
    'users' => 'i-lucide-users',
    'agent_bots' => 'i-lucide-bot',
    'platform_apps' => 'i-lucide-blocks',
    'platform_banners' => 'i-lucide-megaphone'
  }.freeze

  # Routed resources that are reached from other pages instead of the navigation.
  HIDDEN_RESOURCES = %w[account_users access_tokens installation_configs dashboard devise/sessions app_configs instance_statuses settings
                        push_diagnostics].freeze

  # Always in the tab bar on small screens; on phones the others sit behind "More".
  PINNED_RESOURCES = %w[accounts users].freeze

  # Names short enough to sit under an icon in that tab bar.
  TAB_LABELS = {
    'agent_bots' => 'super_admin.navigation.tabs.agent_bots',
    'platform_apps' => 'super_admin.navigation.tabs.platform_apps',
    'platform_banners' => 'super_admin.navigation.tabs.platform_banners'
  }.freeze

  # Heading each feature's page sits under in the settings list. Pages not listed stay at the top.
  SETTINGS_GROUPS = {
    'super_admin.navigation.settings_groups.product' => %w[saml custom_branding captain],
    'super_admin.navigation.settings_groups.channels' => %w[email messenger instagram tiktok],
    'super_admin.navigation.settings_groups.authentication' => %w[google microsoft],
    'super_admin.navigation.settings_groups.integrations' => %w[linear notion slack whatsapp_embedded shopify]
  }.freeze

  def settings_open?
    params[:controller].in? %w[super_admin/settings super_admin/app_configs]
  end

  def monitor_open?
    controller_name.in? %w[instance_statuses push_diagnostics]
  end

  def settings_pages
    @settings_pages ||= begin
      features = SuperAdmin::FeaturesHelper.available_features.select do |_feature, attrs|
        attrs['config_key'].present? && attrs['enabled']
      end

      pages = [['general', { 'config_key' => 'general', 'name' => t('super_admin.settings.pages.general') }]]
      if ChatwootApp.chatwoot_cloud?
        pages << ['internal', { 'config_key' => 'internal', 'name' => t('super_admin.settings.pages.internal'),
                                'description' => t('super_admin.settings.pages.internal_description'), 'icon' => 'i-lucide-lock-keyhole' }]
      end

      pages + features.to_a
    end
  end

  def primary_nav_items
    instance = t('super_admin.navigation.groups.instance')
    [
      { label: t('super_admin.navigation.dashboard'), url: super_admin_root_path, icon: 'i-lucide-layout-dashboard',
        active: current_page?(super_admin_root_path), pinned: true },
      *resource_nav_items,
      { label: t('super_admin.navigation.settings'), url: super_admin_settings_path, icon: 'i-lucide-settings', active: settings_open?,
        pinned: true, group: instance },
      { label: t('super_admin.navigation.monitor'), url: super_admin_instance_status_path, icon: 'i-lucide-activity', active: monitor_open?,
        group: instance }
    ]
  end

  def settings_nav_items(current_config = nil)
    overview = { label: t('super_admin.navigation.overview'), url: super_admin_settings_path, icon: 'i-lucide-layout-grid',
                 active: controller_name == 'settings' }

    [overview] + settings_pages.map do |feature_key, attrs|
      group_key = SETTINGS_GROUPS.keys.find { |key| SETTINGS_GROUPS[key].include?(feature_key) }
      { label: attrs['name'], url: super_admin_app_config_path(config: attrs['config_key']), group: (t(group_key) if group_key),
        icon: attrs['icon'] || 'i-lucide-sliders-horizontal', active: attrs['config_key'] == current_config }
    end
  end

  # Settings and Monitor swap the sidebar for their own links; nil on every other page.
  def section_nav
    if settings_open?
      current_config = params[:config] || 'general' if controller_name == 'app_configs'
      { label: t('super_admin.navigation.settings'), items: settings_nav_items(current_config) }
    elsif monitor_open?
      { label: t('super_admin.navigation.monitor'), items: monitor_nav_items }
    end
  end

  def monitor_nav_items
    [
      { label: t('super_admin.navigation.instance_health'), url: super_admin_instance_status_path, icon: 'i-lucide-heart-pulse',
        active: controller_name == 'instance_statuses' },
      { label: t('super_admin.navigation.push_diagnostics'), url: super_admin_push_diagnostics_path, icon: 'i-lucide-bell-ring',
        active: controller_name == 'push_diagnostics' },
      { label: t('super_admin.navigation.sidekiq_dashboard'), url: sidekiq_web_path, icon: 'i-lucide-layers', external: true }
    ]
  end

  # superadmin.js keeps the tab last opened on a page in this cookie, so the page renders with that tab open.
  def active_tab(tabs)
    path, key = cookies[:super_admin_tab].to_s.split('#', 2)
    path == request.path && tabs.any? { |tab| tab[:key] == key } ? key : tabs.first[:key]
  end

  private

  def resource_nav_items
    Administrate::Namespace.new(namespace).resources.filter_map do |resource|
      next if HIDDEN_RESOURCES.include?(resource.resource)
      next if resource.resource == 'platform_banners' && !ChatwootApp.chatwoot_cloud?

      tab_label_key = TAB_LABELS[resource.resource]
      { label: display_resource_name(resource), tab_label: (t(tab_label_key) if tab_label_key), url: resource_index_route(resource),
        icon: NAV_ICONS[resource.resource], active: nav_link_state(resource) == :active,
        pinned: PINNED_RESOURCES.include?(resource.resource), group: t('super_admin.navigation.groups.manage') }
    end
  end
end
