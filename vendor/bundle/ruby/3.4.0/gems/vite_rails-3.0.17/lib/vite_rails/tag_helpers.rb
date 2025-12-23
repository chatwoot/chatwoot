# frozen_string_literal: true

# Public: Allows to render HTML tags for scripts and styles processed by Vite.
module ViteRails::TagHelpers
  # Public: Renders a script tag for vite/client to enable HMR in development.
  def vite_client_tag(crossorigin: 'anonymous', **options)
    return unless src = vite_manifest.vite_client_src

    javascript_include_tag(src, type: 'module', extname: false, crossorigin: crossorigin, **options)
  end

  # Public: Renders a script tag to enable HMR with React Refresh.
  def vite_react_refresh_tag(**options)
    return unless react_preamble_code = vite_manifest.react_preamble_code

    options[:nonce] = true if Rails::VERSION::MAJOR >= 6 && !options.key?(:nonce)

    javascript_tag(react_preamble_code.html_safe, type: :module, **options)
  end

  # Public: Resolves the path for the specified Vite asset.
  #
  # Example:
  #   <%= vite_asset_path 'calendar.css' %> # => "/vite/assets/calendar-1016838bab065ae1e122.css"
  def vite_asset_path(name, **options)
    path_to_asset vite_manifest.path_for(name, **options)
  end

  # Public: Resolves the url for the specified Vite asset.
  #
  # Example:
  #   <%= vite_asset_url 'calendar.css' %> # => "https://example.com/vite/assets/calendar-1016838bab065ae1e122.css"
  def vite_asset_url(name, **options)
    url_to_asset vite_manifest.path_for(name, **options)
  end

  # Public: Renders a <script> tag for the specified Vite entrypoints.
  def vite_javascript_tag(*names,
                          type: 'module',
                          asset_type: :javascript,
                          skip_preload_tags: false,
                          skip_style_tags: false,
                          crossorigin: 'anonymous',
                          media: 'screen',
                          **options)
    entries = vite_manifest.resolve_entries(*names, type: asset_type)
    tags = javascript_include_tag(*entries.fetch(:scripts), crossorigin: crossorigin, type: type, extname: false, **options)
    tags << vite_preload_tag(*entries.fetch(:imports), crossorigin: crossorigin, **options) unless skip_preload_tags

    options[:extname] = false if Rails::VERSION::MAJOR >= 7

    tags << stylesheet_link_tag(*entries.fetch(:stylesheets), media: media, **options) unless skip_style_tags

    tags
  end

  # Public: Renders a <script> tag for the specified Vite entrypoints.
  def vite_typescript_tag(*names, **options)
    vite_javascript_tag(*names, asset_type: :typescript, **options)
  end

  # Public: Renders a <link> tag for the specified Vite entrypoints.
  def vite_stylesheet_tag(*names, **options)
    style_paths = names.map { |name| vite_asset_path(name, type: :stylesheet) }

    options[:extname] = false if Rails::VERSION::MAJOR >= 7

    stylesheet_link_tag(*style_paths, **options)
  end

  # Public: Renders an <img> tag for the specified Vite asset.
  def vite_image_tag(name, **options)
    if options[:srcset] && !options[:srcset].is_a?(String)
      options[:srcset] = options[:srcset].map do |src_name, size|
        "#{ vite_asset_path(src_name) } #{ size }"
      end.join(', ')
    end

    image_tag(vite_asset_path(name), options)
  end

  # Public: Renders a <picture> tag with one or more Vite asset sources.
  def vite_picture_tag(*sources, &block)
    unless Rails.gem_version >= Gem::Version.new('7.1.0')
      raise NotImplementedError, '`vite_picture_tag` is only available for Rails 7.1 or above.'
    end

    sources.flatten!
    options = sources.extract_options!

    vite_sources = sources.map { |src| vite_asset_path(src) }
    picture_tag(*vite_sources, options, &block)
  end

private

  # Internal: Returns the current manifest loaded by Vite Ruby.
  def vite_manifest
    ViteRuby.instance.manifest
  end

  # Internal: Renders a modulepreload link tag.
  def vite_preload_tag(*sources, crossorigin:, **options)
    asset_paths = sources.map { |source| path_to_asset(source) }
    try(:request).try(
      :send_early_hints,
      'Link' => asset_paths.map { |href|
        %(<#{ href }>; rel=modulepreload; as=script; crossorigin=#{ crossorigin })
      }.join("\n"),
    )
    asset_paths.map { |href|
      tag.link(rel: 'modulepreload', href: href, as: 'script', crossorigin: crossorigin, **options)
    }.join("\n").html_safe
  end
end
