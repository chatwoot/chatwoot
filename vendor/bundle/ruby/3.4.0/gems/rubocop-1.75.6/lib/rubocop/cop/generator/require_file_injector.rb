# frozen_string_literal: true

module RuboCop
  module Cop
    class Generator
      # A class that injects a require directive into the root RuboCop file.
      # It looks for other directives that require files in the same (cop)
      # namespace and injects the provided one in alpha
      class RequireFileInjector
        REQUIRE_PATH = /require_relative ['"](.+)['"]/.freeze

        def initialize(source_path:, root_file_path:, output: $stdout)
          @source_path = Pathname(source_path)
          @root_file_path = Pathname(root_file_path)
          @require_entries = File.readlines(root_file_path)
          @output = output
        end

        def inject
          return if require_exists? || !target_line

          File.write(root_file_path, updated_directives)
          require = injectable_require_directive.chomp
          output.puts "[modify] #{root_file_path} - `#{require}` was injected."
        end

        private

        attr_reader :require_entries, :root_file_path, :source_path, :output

        def require_exists?
          require_entries.any?(injectable_require_directive)
        end

        def updated_directives
          require_entries.insert(target_line, injectable_require_directive).join
        end

        def target_line
          @target_line ||= begin
            in_the_same_department = false
            inject_parts = require_path_fragments(injectable_require_directive)

            require_entries.find.with_index do |entry, index|
              current_entry_parts = require_path_fragments(entry)

              if inject_parts[0..-2] == current_entry_parts[0..-2]
                in_the_same_department = true

                break index if inject_parts.last < current_entry_parts.last
              elsif in_the_same_department
                break index
              end
            end || require_entries.size
          end
        end

        def require_path_fragments(require_directive)
          path = require_directive.match(REQUIRE_PATH)

          path ? path.captures.first.split('/') : []
        end

        def injectable_require_directive
          "require_relative '#{require_path}'\n"
        end

        def require_path
          path = source_path.relative_path_from(root_file_path.dirname)
          path.to_s.delete_suffix('.rb')
        end
      end
    end
  end
end
