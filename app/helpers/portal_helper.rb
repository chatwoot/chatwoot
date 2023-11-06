module PortalHelper
  def generate_portal_bg_color(portal_color, theme)
    base_color = theme == 'dark' ? 'black' : 'white'
    "color-mix(in srgb, #{portal_color} 20%, #{base_color})"
  end

  def generate_portal_bg(portal_color, theme)
    bg_image = theme == 'dark' ? 'hexagon-dark.svg' : 'hexagon-light.svg'
    "url(/assets/images/hc/#{bg_image}) #{generate_portal_bg_color(portal_color, theme)}"
  end

  def generate_gradient_to_bottom(theme)
    base_color = theme == 'dark' ? '#151718' : 'white'
    "linear-gradient(to bottom, transparent, #{base_color})"
  end

  def generate_portal_hover_color(portal_color, theme)
    base_color = theme == 'dark' ? '#1B1B1B' : '#F9F9F9'
    "color-mix(in srgb, #{portal_color} 5%, #{base_color})"
  end

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

  def generate_home_link(portal_slug, portal_locale, theme, is_plain_layout_enabled)
    if is_plain_layout_enabled
      "/hc/#{portal_slug}/#{portal_locale}#{theme.present? && theme != 'system' ? "?theme=#{theme}" : ''}"
    else
      "/hc/#{portal_slug}/#{portal_locale}"
    end
  end

  def generate_category_link(portal_slug, category_locale, category_slug, theme, is_plain_layout_enabled)
    if is_plain_layout_enabled
      "/hc/#{portal_slug}/#{category_locale}/categories/#{category_slug}#{theme.present? && theme != 'system' ? "?theme=#{theme}" : ''}"
    else
      "/hc/#{portal_slug}/#{category_locale}/categories/#{category_slug}"
    end
  end

  def generate_article_link(portal_slug, article_slug, theme, is_plain_layout_enabled)
    if is_plain_layout_enabled
      "/hc/#{portal_slug}/articles/#{article_slug}#{theme.present? && theme != 'system' ? "?theme=#{theme}" : ''}"
    else
      "/hc/#{portal_slug}/articles/#{article_slug}"
    end
  end

  def render_category_content(content)
    ChatwootMarkdownRenderer.new(content).render_markdown_to_plain_text
  end
end
