module PortalHelper
  def generate_portal_bg_color(portal_color, theme)
    base_color = theme == 'dark' ? 'black' : 'white'
    "color-mix(in srgb, #{portal_color} 20%, #{base_color})"
  end

  def generate_portal_bg(portal_color, theme)
    generate_portal_bg_color(portal_color, theme)
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

  def theme_query_string(theme)
    theme.present? && theme != 'system' ? "?theme=#{theme}" : ''
  end

  def generate_home_link(portal_slug, portal_locale, theme, is_plain_layout_enabled)
    if is_plain_layout_enabled
      "/hc/#{portal_slug}/#{portal_locale}#{theme_query_string(theme)}"
    else
      "/hc/#{portal_slug}/#{portal_locale}"
    end
  end

  def generate_category_link(params)
    portal_slug = params[:portal_slug]
    category_locale = params[:category_locale]
    category_slug = params[:category_slug]
    theme = params[:theme]
    is_plain_layout_enabled = params[:is_plain_layout_enabled]

    if is_plain_layout_enabled
      "/hc/#{portal_slug}/#{category_locale}/categories/#{category_slug}#{theme_query_string(theme)}"
    else
      "/hc/#{portal_slug}/#{category_locale}/categories/#{category_slug}"
    end
  end

  def generate_article_link(portal_slug, article_slug, theme, is_plain_layout_enabled)
    if is_plain_layout_enabled
      "/hc/#{portal_slug}/articles/#{article_slug}#{theme_query_string(theme)}"
    else
      "/hc/#{portal_slug}/articles/#{article_slug}"
    end
  end

  def render_category_content(content)
    ChatwootMarkdownRenderer.new(content).render_markdown_to_plain_text
  end

  def thumbnail_bg_color(username)
    colors = ['#6D95BA', '#A4C3C3', '#E19191']
    return colors.sample if username.blank?

    colors[username.length % colors.size]
  end
end
