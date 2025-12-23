# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Use `Rails.root` IO methods instead of passing it to `File`.
      #
      # `Rails.root` is an instance of `Pathname`
      # so we can apply many IO methods directly.
      #
      # This cop works best when used together with
      # `Style/FileRead`, `Style/FileWrite` and `Rails/RootJoinChain`.
      #
      # @safety
      #   This cop is unsafe for autocorrection because ``Dir``'s `children`, `each_child`, `entries`, and `glob`
      #   methods return string element, but these methods of `Pathname` return `Pathname` element.
      #
      # @example
      #   # bad
      #   File.open(Rails.root.join('db', 'schema.rb'))
      #   File.open(Rails.root.join('db', 'schema.rb'), 'w')
      #   File.read(Rails.root.join('db', 'schema.rb'))
      #   File.binread(Rails.root.join('db', 'schema.rb'))
      #   File.write(Rails.root.join('db', 'schema.rb'), content)
      #   File.binwrite(Rails.root.join('db', 'schema.rb'), content)
      #   Dir.glob(Rails.root.join('db', 'schema.rb'))
      #   Dir[Rails.root.join('db', 'schema.rb')]
      #
      #   # good
      #   Rails.root.join('db', 'schema.rb').open
      #   Rails.root.join('db', 'schema.rb').open('w')
      #   Rails.root.join('db', 'schema.rb').read
      #   Rails.root.join('db', 'schema.rb').binread
      #   Rails.root.join('db', 'schema.rb').write(content)
      #   Rails.root.join('db', 'schema.rb').binwrite(content)
      #   Rails.root.glob("db/schema.rb")
      #
      class RootPathnameMethods < Base # rubocop:disable Metrics/ClassLength
        extend AutoCorrector
        include RangeHelp

        MSG = '`%<rails_root>s` is a `Pathname`, so you can use `%<replacement>s`.'

        DIR_GLOB_METHODS = %i[[] glob].to_set.freeze

        DIR_NON_GLOB_METHODS = %i[
          children
          delete
          each_child
          empty?
          entries
          exist?
          mkdir
          open
          rmdir
          unlink
        ].to_set.freeze

        DIR_METHODS = (DIR_GLOB_METHODS + DIR_NON_GLOB_METHODS).freeze

        FILE_METHODS = %i[
          atime
          basename
          binread
          binwrite
          birthtime
          blockdev?
          chardev?
          chmod
          chown
          ctime
          delete
          directory?
          dirname
          empty?
          executable?
          executable_real?
          exist?
          expand_path
          extname
          file?
          fnmatch
          fnmatch?
          ftype
          grpowned?
          join
          lchmod
          lchown
          lstat
          mtime
          open
          owned?
          pipe?
          read
          readable?
          readable_real?
          readlines
          readlink
          realdirpath
          realpath
          rename
          setgid?
          setuid?
          size
          size?
          socket?
          split
          stat
          sticky?
          symlink?
          sysopen
          truncate
          unlink
          utime
          world_readable?
          world_writable?
          writable?
          writable_real?
          write
          zero?
        ].to_set.freeze

        FILE_TEST_METHODS = %i[
          blockdev?
          chardev?
          directory?
          empty?
          executable?
          executable_real?
          exist?
          file?
          grpowned?
          owned?
          pipe?
          readable?
          readable_real?
          setgid?
          setuid?
          size
          size?
          socket?
          sticky?
          symlink?
          world_readable?
          world_writable?
          writable?
          writable_real?
          zero?
        ].to_set.freeze

        FILE_UTILS_METHODS = %i[chmod chown mkdir mkpath rmdir rmtree].to_set.freeze

        RESTRICT_ON_SEND = (DIR_METHODS + FILE_METHODS + FILE_TEST_METHODS + FILE_UTILS_METHODS).to_set.freeze

        # @!method pathname_method_for_ruby_2_5_or_higher(node)
        def_node_matcher :pathname_method_for_ruby_2_5_or_higher, <<~PATTERN
          {
            (send (const {nil? cbase} :Dir) $DIR_METHODS $_ $...)
            (send (const {nil? cbase} {:IO :File}) $FILE_METHODS $_ $...)
            (send (const {nil? cbase} :FileTest) $FILE_TEST_METHODS $_ $...)
            (send (const {nil? cbase} :FileUtils) $FILE_UTILS_METHODS $_ $...)
          }
        PATTERN

        # @!method pathname_method_for_ruby_2_4_or_lower(node)
        def_node_matcher :pathname_method_for_ruby_2_4_or_lower, <<~PATTERN
          {
            (send (const {nil? cbase} :Dir) $DIR_NON_GLOB_METHODS $_ $...)
            (send (const {nil? cbase} {:IO :File}) $FILE_METHODS $_ $...)
            (send (const {nil? cbase} :FileTest) $FILE_TEST_METHODS $_ $...)
            (send (const {nil? cbase} :FileUtils) $FILE_UTILS_METHODS $_ $...)
          }
        PATTERN

        def_node_matcher :dir_glob?, <<~PATTERN
          (send
            (const {cbase nil?} :Dir) DIR_GLOB_METHODS ...)
        PATTERN

        def_node_matcher :rails_root_pathname?, <<~PATTERN
          {
            $#rails_root?
            (send $#rails_root? :join ...)
          }
        PATTERN

        # @!method rails_root?(node)
        def_node_matcher :rails_root?, <<~PATTERN
          (send (const {nil? cbase} :Rails) {:root :public_path})
        PATTERN

        def on_send(node)
          evidence(node) do |method, path, args, rails_root|
            replacement = if dir_glob?(node)
                            build_path_glob_replacement(path)
                          else
                            build_path_replacement(path, method, args)
                          end

            message = format(MSG, rails_root: rails_root.source, replacement: replacement)
            add_offense(node, message: message) do |corrector|
              corrector.replace(node, replacement)
            end
          end
        end

        private

        def evidence(node)
          return if node.method?(:open) && node.parent&.send_type?
          return unless (method, path, args = pathname_method(node)) && (rails_root = rails_root_pathname?(path))

          yield(method, path, args, rails_root)
        end

        def pathname_method(node)
          if target_ruby_version >= 2.5
            pathname_method_for_ruby_2_5_or_higher(node)
          else
            pathname_method_for_ruby_2_4_or_lower(node)
          end
        end

        def build_path_glob_replacement(path)
          receiver = range_between(path.source_range.begin_pos, path.children.first.loc.selector.end_pos).source

          argument = path.arguments.one? ? path.first_argument.source : join_arguments(path.arguments)

          "#{receiver}.glob(#{argument})"
        end

        def build_path_replacement(path, method, args)
          path_replacement = path.source
          if path.arguments? && !path.parenthesized_call?
            path_replacement[' '] = '('
            path_replacement << ')'
          end

          replacement = "#{path_replacement}.#{method}"

          if args.any?
            formatted_args = args.map { |arg| arg.array_type? ? "*#{arg.source}" : arg.source }
            replacement += "(#{formatted_args.join(', ')})"
          end

          replacement
        end

        def include_interpolation?(arguments)
          arguments.any? do |argument|
            argument.children.any? { |child| child.respond_to?(:begin_type?) && child.begin_type? }
          end
        end

        def join_arguments(arguments)
          use_interpolation = false

          joined_arguments = arguments.map do |arg|
            if arg.respond_to?(:value)
              arg.value
            else
              use_interpolation = true
              "\#{#{arg.source}}"
            end
          end.join('/')
          quote = enforce_double_quotes? || include_interpolation?(arguments) || use_interpolation ? '"' : "'"

          "#{quote}#{joined_arguments}#{quote}"
        end

        def enforce_double_quotes?
          string_literals_config['EnforcedStyle'] == 'double_quotes'
        end

        def string_literals_config
          config.for_cop('Style/StringLiterals')
        end
      end
    end
  end
end
