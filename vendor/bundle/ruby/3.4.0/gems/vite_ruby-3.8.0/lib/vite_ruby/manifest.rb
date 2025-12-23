# frozen_string_literal: true

# Public: Registry for accessing resources managed by Vite, using a generated
# manifest file which maps entrypoint names to file paths.
#
# Example:
#   lookup_entrypoint('calendar', type: :javascript)
#   => { "file" => "/vite/assets/calendar-1016838bab065ae1e314.js", "imports" => [] }
#
# NOTE: Using `"autoBuild": true` in `config/vite.json` file will trigger a build
# on demand as needed, before performing any lookup.
class ViteRuby::Manifest
  def initialize(vite_ruby)
    @vite_ruby = vite_ruby
    @build_mutex = Mutex.new if config.auto_build
  end

  # Public: Returns the path for the specified Vite entrypoint file.
  #
  # Raises an error if the resource could not be found in the manifest.
  def path_for(name, **options)
    lookup!(name, **options).fetch('file')
  end

  # Public: Returns scripts, imported modules, and stylesheets for the specified
  # entrypoint files.
  def resolve_entries(*names, **options)
    entries = names.map { |name| lookup!(name, **options) }
    script_paths = entries.map { |entry| entry.fetch('file') }

    imports = dev_server_running? ? [] : entries.flat_map { |entry| entry['imports'] }.compact.uniq
    {
      scripts: script_paths,
      imports: imports.map { |entry| entry.fetch('file') }.uniq,
      stylesheets: dev_server_running? ? [] : (entries + imports).flat_map { |entry| entry['css'] }.compact.uniq,
    }
  end

  # Public: Refreshes the cached mappings by reading the updated manifest files.
  def refresh
    @manifest = load_manifest
  end

  # Public: The path from where the browser can download the Vite HMR client.
  def vite_client_src
    prefix_asset_with_host('@vite/client') if dev_server_running?
  end

  # Public: The content of the preamble needed by the React Refresh plugin.
  def react_refresh_preamble
    if dev_server_running?
      <<~REACT_REFRESH
        <script type="module">
          #{ react_preamble_code }
        </script>
      REACT_REFRESH
    end
  end

  # Public: Source script for the React Refresh plugin.
  def react_preamble_code
    if dev_server_running?
      <<~REACT_PREAMBLE_CODE
        import RefreshRuntime from '#{ prefix_asset_with_host('@react-refresh') }'
        RefreshRuntime.injectIntoGlobalHook(window)
        window.$RefreshReg$ = () => {}
        window.$RefreshSig$ = () => (type) => type
        window.__vite_plugin_react_preamble_installed__ = true
      REACT_PREAMBLE_CODE
    end
  end

protected

  # Internal: Strict version of lookup.
  #
  # Returns a relative path for the asset, or raises an error if not found.
  def lookup!(name, **options)
    lookup(name, **options) || missing_entry_error(name, **options)
  end

  # Internal: Computes the path for a given Vite asset using manifest.json.
  #
  # Returns a relative path, or nil if the asset is not found.
  #
  # Example:
  #   manifest.lookup('calendar.js')
  #   => { "file" => "/vite/assets/calendar-1016838bab065ae1e122.js", "imports" => [] }
  def lookup(name, **options)
    @build_mutex.synchronize { builder.build || (return nil) } if should_build?

    find_manifest_entry resolve_entry_name(name, **options)
  end

private

  # Internal: The prefix used by Vite.js to request files with an absolute path.
  FS_PREFIX = '/@fs/'

  extend Forwardable

  def_delegators :@vite_ruby, :config, :builder, :dev_server_running?

  # NOTE: Auto compilation is convenient when running tests, when the developer
  # won't focus on the frontend, or when running the Vite server is not desired.
  def should_build?
    config.auto_build && !dev_server_running?
  end

  # Internal: Finds the specified entry in the manifest.
  def find_manifest_entry(name)
    if dev_server_running?
      { 'file' => prefix_vite_asset(name) }
    else
      manifest[name]
    end
  end

  # Internal: The parsed data from manifest.json.
  #
  # NOTE: When using build-on-demand in development and testing, the manifest
  # is reloaded automatically before each lookup, to ensure it's always fresh.
  def manifest
    return refresh if config.auto_build

    @manifest ||= load_manifest
  end

  # Internal: Loads and merges the manifest files, resolving the asset paths.
  def load_manifest
    files = config.manifest_paths
    files.map { |path| JSON.parse(path.read) }.inject({}, &:merge).tap(&method(:resolve_references))
  end

  # Internal: Scopes an asset to the output folder in public, as a path.
  def prefix_vite_asset(path)
    File.join(vite_asset_origin || '/', config.public_output_dir, path)
  end

  # Internal: Prefixes an asset with the `asset_host` for tags that do not use
  # the framework tag helpers.
  def prefix_asset_with_host(path)
    File.join(vite_asset_origin || config.asset_host || '/', config.public_output_dir, path)
  end

  # Internal: The origin of assets managed by Vite.
  def vite_asset_origin
    config.origin if dev_server_running? && config.skip_proxy
  end

  # Internal: Resolves the paths that reference a manifest entry.
  def resolve_references(manifest)
    manifest.each_value do |entry|
      entry['file'] = prefix_vite_asset(entry['file'])
      %w[css assets].each do |key|
        entry[key] = entry[key].map { |path| prefix_vite_asset(path) } if entry[key]
      end
      entry['imports']&.map! { |name| manifest.fetch(name) }
    end
  end

  # Internal: Resolves the manifest entry name for the specified resource.
  def resolve_entry_name(name, type: nil)
    return resolve_virtual_entry(name) if type == :virtual

    name = with_file_extension(name.to_s, type)
    raise ArgumentError, "Asset names can not be relative. Found: #{ name }" if name.start_with?('.')

    # Explicit path, relative to the source_code_dir.
    name.sub(%r{^~/(.+)$}) { return Regexp.last_match(1) }

    # Explicit path, relative to the project root.
    name.sub(%r{^/(.+)$}) { return resolve_absolute_entry(Regexp.last_match(1)) }

    # Sugar: Prefix with the entrypoints dir if the path is not nested.
    name.include?('/') ? name : File.join(config.entrypoints_dir, name)
  end

  # Internal: Entry names in the manifest are relative to the Vite.js.
  # During develoment, files outside the root must be requested explicitly.
  def resolve_absolute_entry(name)
    if dev_server_running?
      File.join(FS_PREFIX, config.root, name)
    else
      config.root.join(name).relative_path_from(config.vite_root_dir).to_s
    end
  end

  # Internal: Resolves a virtual entry by walking all the manifest keys.
  def resolve_virtual_entry(name)
    manifest.keys.find { |file| file.include?(name) } || name
  end

  # Internal: Adds a file extension to the file name, unless it already has one.
  def with_file_extension(name, entry_type)
    if File.extname(name).empty? && (ext = extension_for_type(entry_type))
      "#{ name }.#{ ext }"
    else
      name
    end
  end

  # Internal: Allows to receive :javascript and :stylesheet as :type in helpers.
  def extension_for_type(entry_type)
    case entry_type
    when :javascript then 'js'
    when :stylesheet then 'css'
    when :typescript then 'ts'
    else entry_type
    end
  end

  # Internal: Raises a detailed message when an entry is missing in the manifest.
  def missing_entry_error(name, **options)
    raise ViteRuby::MissingEntrypointError.new(
      file_name: resolve_entry_name(name, **options),
      last_build: builder.last_build_metadata,
      manifest: @manifest,
      config: config,
    )
  end
end
