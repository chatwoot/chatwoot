# frozen_string_literal: true

module WebConsole
  # A facade that handles template rendering and composition.
  #
  # It introduces template helpers to ease the inclusion of scripts only on
  # Rails error pages.
  class Template
    # Lets you customize the default templates folder location.
    cattr_accessor :template_paths, default: [ File.expand_path("../templates", __FILE__) ]

    def initialize(env, session)
      @env = env
      @session = session
      @mount_point = Middleware.mount_point
    end

    # Render a template (inferred from +template_paths+) as a plain string.
    def render(template)
      view = View.with_empty_template_cache.with_view_paths(template_paths, instance_values)
      view.render(template: template, layout: false)
    end
  end
end
