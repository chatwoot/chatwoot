class Captain::ToolCatalog::ConnectionStatus
  def self.connected?(hook)
    return false if hook.blank?
    return true if hook.enabled?

    hook.app_id == 'slack' && hook.settings.to_h.with_indifferent_access[:catalog_connected] == true
  end
end
