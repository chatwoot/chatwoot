# frozen_string_literal: true
require 'json'

module Sprockets
  module Npm
    # Internal: Override resolve_alternates to install package.json behavior.
    #
    # load_path    - String environment path
    # logical_path - String path relative to base
    #
    # Returns candidate filenames.
    def resolve_alternates(load_path, logical_path)
      candidates, deps = super

      dirname = File.join(load_path, logical_path)

      if directory?(dirname)
        filename = File.join(dirname, 'package.json')

        if self.file?(filename)
          deps << build_file_digest_uri(filename)
          read_package_directives(dirname, filename) do |path|
            if file?(path)
              candidates << path
            end
          end
        end
      end

      return candidates, deps
    end

    # Internal: Read package.json's main and style directives.
    #
    # dirname  - String path to component directory.
    # filename - String path to package.json.
    #
    # Returns nothing.
    def read_package_directives(dirname, filename)
      package = JSON.parse(File.read(filename), create_additions: false)

      case package['main']
      when String
        yield File.expand_path(package['main'], dirname)
      when nil
        yield File.expand_path('index.js', dirname)
      end

      yield File.expand_path(package['style'], dirname) if package['style']
    end
  end
end
