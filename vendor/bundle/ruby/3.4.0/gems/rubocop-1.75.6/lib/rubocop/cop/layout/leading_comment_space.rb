# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks whether comments have a leading space after the
      # `#` denoting the start of the comment. The leading space is not
      # required for some RDoc special syntax, like `#++`, `#--`,
      # `#:nodoc`, `=begin`- and `=end` comments, "shebang" directives,
      # or rackup options.
      #
      # @example
      #
      #   # bad
      #   #Some comment
      #
      #   # good
      #   # Some comment
      #
      # @example AllowDoxygenCommentStyle: false (default)
      #
      #   # bad
      #
      #   #**
      #   # Some comment
      #   # Another line of comment
      #   #*
      #
      # @example AllowDoxygenCommentStyle: true
      #
      #   # good
      #
      #   #**
      #   # Some comment
      #   # Another line of comment
      #   #*
      #
      # @example AllowGemfileRubyComment: false (default)
      #
      #   # bad
      #
      #   #ruby=2.7.0
      #   #ruby-gemset=myproject
      #
      # @example AllowGemfileRubyComment: true
      #
      #   # good
      #
      #   #ruby=2.7.0
      #   #ruby-gemset=myproject
      #
      # @example AllowRBSInlineAnnotation: false (default)
      #
      #   # bad
      #
      #   include Enumerable #[Integer]
      #
      #   attr_reader :name #: String
      #   attr_reader :age  #: Integer?
      #
      #   #: (
      #   #|   Integer,
      #   #|   String
      #   #| ) -> void
      #   def foo; end
      #
      # @example AllowRBSInlineAnnotation: true
      #
      #   # good
      #
      #   include Enumerable #[Integer]
      #
      #   attr_reader :name #: String
      #   attr_reader :age  #: Integer?
      #
      #   #: (
      #   #|   Integer,
      #   #|   String
      #   #| ) -> void
      #   def foo; end
      #
      # @example AllowSteepAnnotation: false (default)
      #
      #   # bad
      #   [1, 2, 3].each_with_object([]) do |n, list| #$ Array[Integer]
      #     list << n
      #   end
      #
      #   name = 'John'      #: String
      #
      # @example AllowSteepAnnotation: true
      #
      #   # good
      #
      #   [1, 2, 3].each_with_object([]) do |n, list| #$ Array[Integer]
      #     list << n
      #   end
      #
      #   name = 'John'      #: String
      #
      class LeadingCommentSpace < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Missing space after `#`.'

        def on_new_investigation # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          processed_source.comments.each do |comment|
            next unless /\A(?!#\+\+|#--)(#+[^#\s=])/.match?(comment.text)
            next if comment.loc.line == 1 && allowed_on_first_line?(comment)
            next if shebang_continuation?(comment)
            next if doxygen_comment_style?(comment)
            next if gemfile_ruby_comment?(comment)
            next if rbs_inline_annotation?(comment)
            next if steep_annotation?(comment)

            add_offense(comment) do |corrector|
              expr = comment.source_range

              corrector.insert_after(hash_mark(expr), ' ')
            end
          end
        end

        private

        def hash_mark(expr)
          range_between(expr.begin_pos, expr.begin_pos + 1)
        end

        def allowed_on_first_line?(comment)
          shebang?(comment) || (rackup_config_file? && rackup_options?(comment))
        end

        def shebang?(comment)
          comment.text.start_with?('#!')
        end

        def shebang_continuation?(comment)
          return false unless shebang?(comment)
          return true if comment.loc.line == 1

          previous_line_comment = processed_source.comment_at_line(comment.loc.line - 1)
          return false unless previous_line_comment

          # If the comment is a shebang but not on the first line, check if the previous
          # line has a shebang comment that wasn't marked as an offense; if so, this comment
          # continues the shebang and is acceptable.
          shebang?(previous_line_comment) &&
            !current_offense_locations.include?(previous_line_comment.source_range)
        end

        def rackup_options?(comment)
          comment.text.start_with?('#\\')
        end

        def rackup_config_file?
          File.basename(processed_source.file_path).eql?('config.ru')
        end

        def allow_doxygen_comment?
          cop_config['AllowDoxygenCommentStyle']
        end

        def doxygen_comment_style?(comment)
          allow_doxygen_comment? && comment.text.start_with?('#*')
        end

        def allow_gemfile_ruby_comment?
          cop_config['AllowGemfileRubyComment']
        end

        def gemfile?
          File.basename(processed_source.file_path).eql?('Gemfile')
        end

        def ruby_comment_in_gemfile?(comment)
          gemfile? && comment.text.start_with?('#ruby')
        end

        def gemfile_ruby_comment?(comment)
          allow_gemfile_ruby_comment? && ruby_comment_in_gemfile?(comment)
        end

        def allow_rbs_inline_annotation?
          cop_config['AllowRBSInlineAnnotation']
        end

        def rbs_inline_annotation?(comment)
          allow_rbs_inline_annotation? && comment.text.start_with?(/#:|#\[.+\]|#\|/)
        end

        def allow_steep_annotation?
          cop_config['AllowSteepAnnotation']
        end

        def steep_annotation?(comment)
          allow_steep_annotation? && comment.text.start_with?(/#[$:]/)
        end
      end
    end
  end
end
