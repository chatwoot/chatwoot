module PortalHelper
  def language_name(locale)
    language_map = YAML.load_file(Rails.root.join('config/languages/language_map.yml'))
    language_map[locale] || locale
  end

  def get_theme_names(theme)
    if theme == 'light'
      I18n.t('public_portal.header.appearance.light')
    elsif theme == 'dark'
      I18n.t('public_portal.header.appearance.dark')
    else
      I18n.t('public_portal.header.appearance.system')
    end
  end

  def get_theme_icon(theme)
    if theme == 'light'
      'icons/sun'
    elsif theme == 'dark'
      'icons/moon'
    else
      'icons/monitor'
    end
  end

  def generate_article_link(portal_slug, article_slug, theme)
    "/hc/#{portal_slug}/articles/#{article_slug}#{theme.present? && theme != 'system' ? "?theme=#{theme}" : ''}"
  end

  def render_category_content(content)
    ChatwootMarkdownRenderer.new(content).render_markdown_to_plain_text
  end
end
