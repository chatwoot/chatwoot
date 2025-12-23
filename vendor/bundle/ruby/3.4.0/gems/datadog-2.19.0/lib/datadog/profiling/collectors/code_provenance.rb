# frozen_string_literal: true

require "set"
require "json"

module Datadog
  module Profiling
    module Collectors
      # Collects library metadata for loaded files ($LOADED_FEATURES) in the Ruby VM.
      # The output of this class is a list of libraries which have been require'd (in particular, this is
      # not a list of ALL installed libraries).
      #
      # This metadata powers grouping and categorization of stack trace data.
      #
      # This class acts both as a collector (collecting data) as well as a recorder (records/serializes it)
      class CodeProvenance
        def initialize(
          standard_library_path: RbConfig::CONFIG.fetch("rubylibdir"),
          ruby_native_filename: Datadog::Profiling::Collectors::Stack._native_ruby_native_filename
        )
          @libraries_by_name = {}
          @libraries_by_path = {}
          @seen_files = Set.new
          @seen_libraries = Set.new

          record_library(
            Library.new(
              kind: "standard library",
              name: "stdlib",
              version: RUBY_VERSION,
              path: standard_library_path,
              extra_path: ruby_native_filename,
            )
          )
        end

        def refresh(loaded_files: $LOADED_FEATURES, loaded_specs: Gem.loaded_specs.values)
          record_loaded_specs(loaded_specs)
          record_loaded_files(loaded_files)

          self
        end

        def generate_json
          JSON.generate(v1: seen_libraries.to_a)
        end

        private

        attr_reader \
          :libraries_by_name,
          :libraries_by_path,
          :seen_files,
          :seen_libraries

        def record_library(library)
          libraries_by_name[library.name] = library
          libraries_by_path[library.path] = library
        end

        # Ruby hash maps are guaranteed to keep the insertion order of keys. Here, we sort @libraries_by_path so
        # that the hash can be iterated in reverse order of paths.
        #
        # Why we do this: We do this to make sure that if there are libraries with paths that are prefixes of other
        # libraries, e.g. '/home/foo' and '/home/foo/bar', we match to the longest path first.
        # When reverse sorting paths as strings, '/home/foo/bar' will come before '/home/foo'.
        #
        # This way, when we iterate the @libraries_by_path hash, we know the first hit will also be the longest.
        #
        # Alternatively/in the future we could instead use a trie to match paths, but I doubt for the data sizes we're
        # looking at that a trie is that much faster than using Ruby's built-in native collections.
        def sort_libraries_by_longest_path_first
          @libraries_by_path = @libraries_by_path.sort.reverse!.to_h
        end

        def record_loaded_specs(loaded_specs)
          recorded_library = false

          loaded_specs.each do |spec|
            next if libraries_by_name.key?(spec.name)

            record_library(
              Library.new(
                kind: "library",
                name: spec.name,
                version: spec.version,
                path: spec.gem_dir,
                extra_path: (spec.extension_dir if spec.extensions.any?),
              )
            )
            recorded_library = true
          end

          sort_libraries_by_longest_path_first if recorded_library
        end

        def record_loaded_files(loaded_files)
          loaded_files.each do |file_path|
            next if seen_files.include?(file_path)

            seen_files << file_path

            # NOTE: Don't use .find, it allocates a lot more memory (see commit that added this note for details)
            libraries_by_path.any? do |library_path, library|
              seen_libraries << library if file_path.start_with?(library_path)
            end
          end
        end

        # Represents metadata we have for a ruby gem
        #
        # Important note: This class gets encoded to JSON with the built-in JSON gem. But, we've found that in some
        # buggy cases, some Ruby gems monkey patch the built-in JSON gem and forget to call #to_json, and instead
        # encode this class instance-field-by-instance-field.
        #
        # Thus, this class was setup to match the JSON output. Take this into consideration if you are adding new
        # fields. (Also, we have a spec for this)
        class Library
          attr_reader :kind, :name, :version

          def initialize(kind:, name:, version:, path:, extra_path: nil)
            extra_path = nil if extra_path&.empty?
            @kind = kind.freeze
            @name = name.dup.freeze
            @version = version.to_s.dup.freeze
            @paths = [path.dup.freeze, extra_path.dup.freeze].compact.freeze
            freeze
          end

          def to_json(arg = nil)
            {kind: @kind, name: @name, version: @version, paths: @paths}.to_json(arg)
          end

          def path
            @paths.first
          end
        end
      end
    end
  end
end
