# frozen_string_literal: true
require 'set'
require 'sprockets/http_utils'
require 'sprockets/path_dependency_utils'
require 'sprockets/uri_utils'

module Sprockets
  module Resolve
    include HTTPUtils, PathDependencyUtils, URIUtils

    # Public: Find Asset URI for given a logical path by searching the
    # environment's load paths.
    #
    #     resolve("application.js")
    #     # => "file:///path/to/app/javascripts/application.js?type=application/javascript"
    #
    # An accept content type can be given if the logical path doesn't have a
    # format extension.
    #
    #     resolve("application", accept: "application/javascript")
    #     # => "file:///path/to/app/javascripts/application.coffee?type=application/javascript"
    #
    # The String Asset URI is returned or nil if no results are found.
    def resolve(path, load_paths: config[:paths], accept: nil, pipeline: nil, base_path: nil)
      paths = load_paths

      if valid_asset_uri?(path)
        uri, deps = resolve_asset_uri(path)
      elsif absolute_path?(path)
        filename, type, deps = resolve_absolute_path(paths, path, accept)
      elsif relative_path?(path)
        filename, type, path_pipeline, deps, index_alias = resolve_relative_path(paths, path, base_path, accept)
      else
        filename, type, path_pipeline, deps, index_alias = resolve_logical_path(paths, path, accept)
      end

      if filename
        uri = build_asset_uri(filename, type: type, pipeline: pipeline || path_pipeline, index_alias: index_alias)
      end

      return uri, deps
    end

    # Public: Same as resolve() but raises a FileNotFound exception instead of
    # nil if no assets are found.
    def resolve!(path, **kargs)
      uri, deps = resolve(path, **kargs)

      unless uri
        message = +"couldn't find file '#{path}'"

        if relative_path?(path) && kargs[:base_path]
          load_path, _ = paths_split(config[:paths], kargs[:base_path])
          message << " under '#{load_path}'"
        end

        message << " with type '#{kargs[:accept]}'" if kargs[:accept]

        load_paths = kargs[:load_paths] || config[:paths]
        message << "\nChecked in these paths: \n  #{ load_paths.join("\n  ") }"

        raise FileNotFound, message
      end

      return uri, deps
    end

    protected

      # Internal: Finds an asset given a URI
      #
      # uri - String. Contains file:// scheme, absolute path to
      #       file.
      #       e.g. "file:///Users/schneems/sprockets/test/fixtures/default/gallery.js?type=application/javascript"
      #
      # Returns Array. Contains a String uri and Set of dependencies
      def resolve_asset_uri(uri)
        filename, _ = URIUtils.parse_asset_uri(uri)
        return uri, Set.new( [URIUtils.build_file_digest_uri(filename)] )
      end

      # Internal: Finds a file in a set of given paths
      #
      # paths    - Array of Strings.
      # filename - String containing absolute path to a file including extension.
      #            e.g. "/Users/schneems/sprockets/test/fixtures/asset/application.js"
      # accept   - String. A Quality value incoded set of
      #            mime types that we are looking for. Can be nil.
      #            e.g. "application/javascript" or "text/css, */*"
      #
      # Returns Array. Filename, type, path_pipeline, deps, index_alias
      def resolve_absolute_path(paths, filename, accept)
        deps = Set.new
        filename = File.expand_path(filename)

        # Ensure path is under load paths
        return nil, nil, deps unless PathUtils.paths_split(paths, filename)

        _, mime_type = PathUtils.match_path_extname(filename, config[:mime_exts])
        type = resolve_transform_type(mime_type, accept)
        return nil, nil, deps if accept && !type

        return nil, nil, deps unless file?(filename)

        deps << URIUtils.build_file_digest_uri(filename)
        return filename, type, deps
      end

      # Internal: Finds a relative file in a set of given paths
      #
      # paths   - Array of Strings.
      # path    - String. A relative filename with or without extension
      #           e.g. "./jquery" or "../foo.js"
      # dirname - String. Base path where we start looking for the given file.
      # accept  - String. A Quality value incoded set of
      #           mime types that we are looking for. Can be nil.
      #           e.g. "application/javascript" or "text/css, */*"
      #
      # Returns Array. Filename, type, path_pipeline, deps, index_alias
      def resolve_relative_path(paths, path, dirname, accept)
        filename = File.expand_path(path, dirname)
        load_path, _ = PathUtils.paths_split(paths, dirname)
        if load_path && logical_path = PathUtils.split_subpath(load_path, filename)
          resolve_logical_path([load_path], logical_path, accept)
        else
          return nil, nil, nil, Set.new
        end
      end

      # Internal: Finds a file in a set of given paths
      #
      # paths        - Array of Strings.
      # logical_path - String. A filename with extension
      #                e.g. "coffee/foo.js" or "foo.js"
      # accept       - String. A Quality value incoded set of
      #                mime types that we are looking for. Can be nil.
      #                e.g. "application/javascript" or "text/css, */*"
      #
      # Finds a file on the given paths.
      #
      # Returns Array. Filename, type, path_pipeline, deps, index_alias
      def resolve_logical_path(paths, logical_path, accept)
        extname, mime_type = PathUtils.match_path_extname(logical_path, config[:mime_exts])
        logical_name = logical_path.chomp(extname)

        extname, pipeline = PathUtils.match_path_extname(logical_name, config[:pipeline_exts])
        logical_name = logical_name.chomp(extname)

        parsed_accept = parse_accept_options(mime_type, accept)
        transformed_accepts = expand_transform_accepts(parsed_accept)

        filename, mime_type, deps, index_alias = resolve_under_paths(paths, logical_name, transformed_accepts)

        if filename
          deps << build_file_digest_uri(filename)
          type = resolve_transform_type(mime_type, parsed_accept)
          return filename, type, pipeline, deps, index_alias
        else
          return nil, nil, nil, deps
        end
      end

      # Internal: Finds a file in a set of given paths
      #
      # paths        - Array of Strings.
      # logical_name - String. A filename without extension
      #                e.g. "application" or "coffee/foo"
      # accepts      - Array of array containing mime/version pairs
      #                e.g. [["application/javascript", 1.0]]
      #
      # Finds a file with the same name as `logical_name` or "index" inside
      # of the `logical_name` directory that matches a valid mime-type/version from
      # `accepts`.
      #
      # Returns Array. Filename, type, dependencies, and index_alias
      def resolve_under_paths(paths, logical_name, accepts)
        deps = Set.new
        return nil, nil, deps if accepts.empty?

        # TODO: Allow new path resolves to be registered
        @resolvers ||= [
          method(:resolve_main_under_path),
          method(:resolve_alts_under_path),
          method(:resolve_index_under_path)
        ]
        mime_exts = config[:mime_exts]

        paths.each do |load_path|
          candidates = []
          @resolvers.each do |fn|
            result = fn.call(load_path, logical_name, mime_exts)
            candidates.concat(result[0])
            deps.merge(result[1])
          end

          candidate = HTTPUtils.find_best_q_match(accepts, candidates) do |c, matcher|
            match_mime_type?(c[:type] || "application/octet-stream", matcher)
          end
          return candidate[:filename], candidate[:type], deps, candidate[:index_alias] if candidate
        end

        return nil, nil, deps
      end

      # Internal: Finds candidate files on a given path
      #
      # load_path    - String. An absolute path to a directory
      # logical_name - String. A filename without extension
      #                e.g. "application" or "coffee/foo"
      # mime_exts    - Hash of file extensions and their mime types
      #                e.g. {".xml.builder"=>"application/xml+builder"}
      #
      # Finds files that match a given `logical_name` with an acceptable
      # mime type that is included in `mime_exts` on the `load_path`.
      #
      # Returns Array. First element is an Array of hashes or empty, second is a String
      def resolve_main_under_path(load_path, logical_name, mime_exts)
        dirname    = File.dirname(File.join(load_path, logical_name))
        candidates = self.find_matching_path_for_extensions(dirname, File.basename(logical_name), mime_exts)
        candidates.map! do |c|
          { filename: c[0], type: c[1] }
        end
        return candidates, [ URIUtils.build_file_digest_uri(dirname) ]
      end


      # Internal: Finds candidate index files in a given path
      #
      # load_path    - String. An absolute path to a directory
      # logical_name - String. A filename without extension
      #                e.g. "application" or "coffee/foo"
      # mime_exts    - Hash of file extensions and their mime types
      #                e.g. {".xml.builder"=>"application/xml+builder"}
      #
      # Looking in the given `load_path` this method will find all files under the `logical_name` directory
      # that are named `index` and have a matching mime type in `mime_exts`.
      #
      # Returns Array. First element is an Array of hashes or empty, second is a String
      def resolve_index_under_path(load_path, logical_name, mime_exts)
        dirname = File.join(load_path, logical_name)

        if self.directory?(dirname)
          candidates = self.find_matching_path_for_extensions(dirname, "index".freeze, mime_exts)
        else
          candidates = []
        end

        candidates.map! do |c|
          { filename: c[0],
            type: c[1],
            index_alias: compress_from_root(c[0].sub(/\/index(\.[^\/]+)$/, '\1')) }
        end

        return candidates, [ URIUtils.build_file_digest_uri(dirname) ]
      end

      def resolve_alts_under_path(load_path, logical_name, mime_exts)
        filenames, deps = self.resolve_alternates(load_path, logical_name)
        filenames.map! do |fn|
          _, mime_type = PathUtils.match_path_extname(fn, mime_exts)
          { filename: fn, type: mime_type }
        end
        return filenames, deps
      end

      # Internal: Converts mimetype into accept Array
      #
      # - mime_type     - String, optional. e.g. "text/html"
      # - explicit_type - String, optional. e.g. "application/javascript"
      #
      # When called with an explicit_type and a mime_type, only a mime_type
      # that matches the given explicit_type will be accepted.
      #
      # Returns Array of Array
      #
      #     [["application/javascript", 1.0]]
      #     [["*/*", 1.0]]
      #     []
      def parse_accept_options(mime_type, explicit_type)
        if mime_type
          return [[mime_type, 1.0]] if explicit_type.nil?
          return [[mime_type, 1.0]] if HTTPUtils.parse_q_values(explicit_type).any? { |accept, _| HTTPUtils.match_mime_type?(mime_type, accept) }
          return []
        end

        accepts = HTTPUtils.parse_q_values(explicit_type)
        accepts << ['*/*'.freeze, 1.0] if accepts.empty?
        return accepts
      end

      def resolve_alternates(load_path, logical_name)
        return [], Set.new
      end
  end
end
