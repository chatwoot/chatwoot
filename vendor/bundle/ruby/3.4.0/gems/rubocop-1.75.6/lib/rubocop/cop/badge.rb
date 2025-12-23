# frozen_string_literal: true

module RuboCop
  module Cop
    # Identifier of all cops containing a department and cop name.
    #
    # All cops are identified by their badge. For example, the badge for
    # `RuboCop::Cop::Layout::IndentationStyle` is `Layout/IndentationStyle`.
    # Badges can be parsed as either `Department/CopName` or just `CopName` to
    # allow for badge references in source files that omit the department for
    # RuboCop to infer.
    class Badge
      attr_reader :department, :department_name, :cop_name

      def self.for(class_name)
        parts = class_name.split('::')
        name_deep_enough = parts.length >= 4
        new(name_deep_enough ? parts[2..] : parts.last(2))
      end

      @parse_cache = {}

      def self.parse(identifier)
        @parse_cache[identifier] ||= new(identifier.split('/').map! { |i| camel_case(i) })
      end

      def self.camel_case(name_part)
        return 'RSpec' if name_part == 'rspec'
        return name_part unless name_part.match?(/^[a-z]|_[a-z]/)

        name_part.gsub(/^[a-z]|_[a-z]/) { |match| match[-1, 1].upcase }
      end

      def initialize(class_name_parts)
        department_parts = class_name_parts[0...-1]
        @department = (department_parts.join('/').to_sym unless department_parts.empty?)
        @department_name = @department&.to_s
        @cop_name = class_name_parts.last
      end

      def ==(other)
        hash == other.hash
      end
      alias eql? ==

      def hash
        # Do hashing manually to reduce Array allocations.
        department.hash ^ cop_name.hash # rubocop:disable Security/CompoundHash
      end

      def match?(other)
        cop_name == other.cop_name && (!qualified? || department == other.department)
      end

      def to_s
        @to_s ||= qualified? ? "#{department}/#{cop_name}" : cop_name
      end

      def qualified?
        !department.nil?
      end

      def with_department(department)
        self.class.new([department.to_s.split('/'), cop_name].flatten)
      end
    end
  end
end
