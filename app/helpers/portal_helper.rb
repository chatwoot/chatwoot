module PortalHelper
  def generate_portal_bg_color(portal_color, theme)
    base_color = theme == 'dark' ? 'black' : 'white'
    "color-mix(in srgb, #{portal_color} 10%, #{base_color})"
  end

  def generate_portal_bg(portal_color, theme)
    bg_image = theme == 'dark' ? 'grid_dark.svg' : 'grid.svg'
    "background: url(/assets/images/hc/#{bg_image}) #{generate_portal_bg_color(portal_color, theme)}"
  end

  def language_name(locale)
    language_map = YAML.load_file(Rails.root.join('config/languages/language_map.yml'))
    language_map[locale] || locale
  end
end
