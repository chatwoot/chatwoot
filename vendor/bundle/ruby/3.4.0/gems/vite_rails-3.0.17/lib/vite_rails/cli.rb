# frozen_string_literal: true

require 'vite_rails'

module ViteRails::CLI
end

module ViteRails::CLI::Build
  def call(**options)
    ensure_rails_init
    super
  end

  # Internal: Attempts to initialize the Rails application.
  def ensure_rails_init
    require File.expand_path('config/environment', Dir.pwd)
  rescue StandardError, LoadError => error
    $stderr << "Unable to initialize Rails application before Vite build:\n\n\t#{ error.message }\n\n"
  end
end

# Internal: Extends the base installation script from Vite Ruby to work for a
# typical Rails app.
module ViteRails::CLI::Install
  RAILS_TEMPLATES = Pathname.new(File.expand_path('../../templates', __dir__))

  # Override: Setup a typical apps/web Hanami app to use Vite.
  def setup_app_files
    cp RAILS_TEMPLATES.join('config/rails-vite.json'), config.config_path
    if dir = %w[app/javascript app/packs].find { |path| root.join(path).exist? }
      replace_first_line config.config_path, 'app/frontend', %(    "sourceCodeDir": "#{ dir }",)
    end
    setup_content_security_policy root.join('config/initializers/content_security_policy.rb')
    append root.join('Procfile.dev'), 'web: bin/rails s'
  end

  # Internal: Configure CSP rules that allow to load @vite/client correctly.
  def setup_content_security_policy(csp_file)
    return unless csp_file.exist?

    inject_line_after csp_file, 'policy.script_src', <<~CSP
          # You may need to enable this in production as well depending on your setup.
      #    policy.script_src *policy.script_src, :blob if Rails.env.test?
    CSP
    inject_line_after csp_file, 'policy.connect_src', <<~CSP
          # Allow @vite/client to hot reload changes in development
      #    policy.connect_src *policy.connect_src, "ws://\#{ ViteRuby.config.host_with_port }" if Rails.env.development?
    CSP
    inject_line_after csp_file, 'policy.script_src', <<~CSP
          # Allow @vite/client to hot reload javascript changes in development
      #    policy.script_src *policy.script_src, :unsafe_eval, "http://\#{ ViteRuby.config.host_with_port }" if Rails.env.development?
    CSP
    inject_line_after csp_file, 'policy.style_src', <<~CSP
          # Allow @vite/client to hot reload style changes in development
      #    policy.style_src *policy.style_src, :unsafe_inline if Rails.env.development?
    CSP
  end

  # Override: Create a sample JS file and attempt to inject it in an HTML template.
  def install_sample_files
    unless config.resolved_entrypoints_dir.join('application.js').exist?
      cp RAILS_TEMPLATES.join('entrypoints/application.js'), config.resolved_entrypoints_dir.join('application.js')
    end

    if (layout_file = root.join('app/views/layouts/application.html.erb')).exist?
      inject_line_before layout_file, '</head>', <<-HTML
    <%= vite_client_tag %>
    <%= vite_javascript_tag 'application' %>
    <!--
      If using a TypeScript entrypoint file:
        vite_typescript_tag 'application'

      If using a .jsx or .tsx entrypoint, add the extension:
        vite_javascript_tag 'application.jsx'

      Visit the guide for more information: https://vite-ruby.netlify.app/guide/rails
    -->
      HTML
    end
  end
end

ViteRuby::CLI::Build.prepend(ViteRails::CLI::Build)
ViteRuby::CLI::Install.prepend(ViteRails::CLI::Install)
