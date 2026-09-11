module Concerns::CaptainHelpCenterDocumentable
  HELP_CENTER_ARTICLE_PATH = %r{\A/hc/([^/]+)/articles/([^/]+?)(?:\.md)?/?\z}

  private

  def local_help_center_source
    return if external_link.blank?

    uri = URI.parse(external_link)
    return unless (path_match = uri.path&.match(HELP_CENTER_ARTICLE_PATH))

    portal = account.portals.find_by(slug: path_match[1])
    return unless portal && local_help_center_host?(uri.host, portal)

    [portal, path_match[2]]
  rescue URI::InvalidURIError
    nil
  end

  def set_help_center_article_id
    help_center_source = local_help_center_source
    return self.metadata = metadata.except('help_center_article_id') unless help_center_source

    portal, article_slug = help_center_source
    self.help_center_article_id = portal.articles.find_by(slug: article_slug)&.id
  end

  def local_help_center_host?(host, portal)
    local_hosts = [portal.custom_domain, ChatwootApp.help_center_root, ENV.fetch('FRONTEND_URL', nil)].filter_map { |url| host_from(url) }
    local_hosts.include?(host&.downcase)
  end

  def host_from(url)
    return if url.blank?

    URI.parse(url.include?('://') ? url : "https://#{url}").host&.downcase
  rescue URI::InvalidURIError
    nil
  end
end
