# frozen_string_literal: true

module RuboCop
  module Cop
    module Migration
      # Check that cop names in rubocop:disable comments are given with
      # department name.
      class DepartmentName < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Department name is missing.'

        DISABLE_COMMENT_FORMAT = /\A(# *rubocop *: *((dis|en)able|todo) +)(.*)/.freeze

        # The token that makes up a disable comment.
        # The allowed specification for comments after `# rubocop: disable` is
        # `DepartmentName/CopName` or` all`.
        DISABLING_COPS_CONTENT_TOKEN = %r{[A-Za-z]+/[A-Za-z]+|all}.freeze

        def on_new_investigation
          processed_source.comments.each do |comment|
            next if comment.text !~ DISABLE_COMMENT_FORMAT

            offset = Regexp.last_match(1).length

            Regexp.last_match(4).scan(/[^,]+|\W+/) do |name|
              trimmed_name = name.strip

              unless valid_content_token?(trimmed_name)
                check_cop_name(trimmed_name, comment, offset)
              end

              break if contain_unexpected_character_for_department_name?(name)

              offset += name.length
            end
          end
        end

        private

        def disable_comment_offset
          Regexp.last_match(1).length
        end

        def check_cop_name(name, comment, offset)
          start = comment.source_range.begin_pos + offset
          range = range_between(start, start + name.length)

          add_offense(range) do |corrector|
            cop_name = range.source
            qualified_cop_name = Registry.global.qualified_cop_name(cop_name, nil, warn: false)

            unless qualified_cop_name.include?('/')
              qualified_cop_name = qualified_legacy_cop_name(cop_name)
            end

            corrector.replace(range, qualified_cop_name)
          end
        end

        def valid_content_token?(content_token)
          /\W+/.match?(content_token) ||
            DISABLING_COPS_CONTENT_TOKEN.match?(content_token) ||
            Registry.global.department?(content_token)
        end

        def contain_unexpected_character_for_department_name?(name)
          name.match?(%r{[^A-Za-z/, ]})
        end

        def qualified_legacy_cop_name(cop_name)
          legacy_cop_names = RuboCop::ConfigObsoletion.legacy_cop_names

          legacy_cop_names.detect { |legacy_cop_name| legacy_cop_name.split('/')[1] == cop_name }
        end
      end
    end
  end
end
