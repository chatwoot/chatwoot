# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality shared by Uncommunicative cops
    module UncommunicativeName
      CASE_MSG = 'Only use lowercase characters for %<name_type>s.'
      NUM_MSG = 'Do not end %<name_type>s with a number.'
      LENGTH_MSG = '%<name_type>s must be at least %<min>s characters long.'
      FORBIDDEN_MSG = 'Do not use %<name>s as a name for a %<name_type>s.'

      def check(node, args)
        args.each do |arg|
          # Argument names might be "_" or prefixed with "_" to indicate they
          # are unused. Trim away this prefix and only analyse the basename.
          name_child = arg.children.first
          next if name_child.nil?

          full_name = name_child.to_s
          next if full_name == '_'

          name = full_name.gsub(/\A(_+)/, '')
          next if allowed_names.include?(name)

          length = full_name.size
          length += 1 if arg.restarg_type?
          length += 2 if arg.kwrestarg_type?

          range = arg_range(arg, length)
          issue_offenses(node, range, name)
        end
      end

      private

      def issue_offenses(node, range, name)
        forbidden_offense(node, range, name) if forbidden_names.include?(name)
        case_offense(node, range) if uppercase?(name)
        length_offense(node, range) unless long_enough?(name)
        return if allow_nums

        num_offense(node, range) if ends_with_num?(name)
      end

      def case_offense(node, range)
        add_offense(range, message: format(CASE_MSG, name_type: name_type(node)))
      end

      def uppercase?(name)
        /[[:upper:]]/.match?(name)
      end

      def name_type(node)
        @name_type ||= case node.type
                       when :block then 'block parameter'
                       when :def, :defs then 'method parameter'
                       end
      end

      def num_offense(node, range)
        add_offense(range, message: format(NUM_MSG, name_type: name_type(node)))
      end

      def ends_with_num?(name)
        /\d/.match?(name[-1])
      end

      def length_offense(node, range)
        message = format(LENGTH_MSG, name_type: name_type(node).capitalize, min: min_length)

        add_offense(range, message: message)
      end

      def long_enough?(name)
        name.size >= min_length
      end

      def arg_range(arg, length)
        begin_pos = arg.source_range.begin_pos
        Parser::Source::Range.new(processed_source.buffer, begin_pos, begin_pos + length)
      end

      def forbidden_offense(node, range, name)
        add_offense(range, message: format(FORBIDDEN_MSG, name: name, name_type: name_type(node)))
      end

      def allowed_names
        cop_config['AllowedNames']
      end

      def forbidden_names
        cop_config['ForbiddenNames']
      end

      def allow_nums
        cop_config['AllowNamesEndingInNumbers']
      end

      def min_length
        cop_config['MinNameLength']
      end
    end
  end
end
