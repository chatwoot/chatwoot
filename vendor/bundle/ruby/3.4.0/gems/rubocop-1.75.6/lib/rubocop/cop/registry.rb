# frozen_string_literal: true

module RuboCop
  module Cop
    # Error raised when an unqualified cop name is used that could
    # refer to two or more cops under different departments
    class AmbiguousCopName < RuboCop::Error
      MSG = 'Ambiguous cop name `%<name>s` used in %<origin>s needs ' \
            'department qualifier. Did you mean %<options>s?'

      def initialize(name, origin, badges)
        super(
          format(MSG, name: name, origin: origin, options: badges.to_a.join(' or '))
        )
      end
    end

    # Registry that tracks all cops by their badge and department.
    class Registry
      include Enumerable

      def self.all
        global.without_department(:Test).cops
      end

      def self.qualified_cop_name(name, origin, warn: true)
        global.qualified_cop_name(name, origin, warn: warn)
      end

      # Changes momentarily the global registry
      # Intended for testing purposes
      def self.with_temporary_global(temp_global = global.dup)
        previous = @global
        @global = temp_global
        yield
      ensure
        @global = previous
      end

      def self.reset!
        @global = new
      end

      def self.qualified_cop?(name)
        badge = Badge.parse(name)
        global.qualify_badge(badge).first == badge
      end

      attr_reader :options

      def initialize(cops = [], options = {})
        @registry = {}
        @departments = {}
        @cops_by_cop_name = Hash.new { |hash, key| hash[key] = [] }

        @enrollment_queue = cops
        @options = options

        @enabled_cache = {}.compare_by_identity
        @disabled_cache = {}.compare_by_identity
      end

      def enlist(cop)
        @enrollment_queue << cop
      end

      def dismiss(cop)
        raise "Cop #{cop} could not be dismissed" unless @enrollment_queue.delete(cop)
      end

      # @return [Array<Symbol>] list of departments for current cops.
      def departments
        clear_enrollment_queue
        @departments.keys
      end

      # @return [Registry] Cops for that specific department.
      def with_department(department)
        clear_enrollment_queue
        with(@departments.fetch(department, []))
      end

      # @return [Registry] Cops not for a specific department.
      def without_department(department)
        clear_enrollment_queue
        without_department = @departments.dup
        without_department.delete(department)

        with(without_department.values.flatten)
      end

      # @return [Boolean] Checks if given name is department
      def department?(name)
        departments.include?(name.to_sym)
      end

      def contains_cop_matching?(names)
        cops.any? { |cop| cop.match?(names) }
      end

      # Convert a user provided cop name into a properly namespaced name
      #
      # @example gives back a correctly qualified cop name
      #
      #   registry = RuboCop::Cop::Registry
      #   registry.qualified_cop_name('Layout/EndOfLine', '') # => 'Layout/EndOfLine'
      #
      # @example fixes incorrect namespaces
      #
      #   registry = RuboCop::Cop::Registry
      #   registry.qualified_cop_name('Lint/EndOfLine', '') # => 'Layout/EndOfLine'
      #
      # @example namespaces bare cop identifiers
      #
      #   registry = RuboCop::Cop::Registry
      #   registry.qualified_cop_name('EndOfLine', '') # => 'Layout/EndOfLine'
      #
      # @example passes back unrecognized cop names
      #
      #   registry = RuboCop::Cop::Registry
      #   registry.qualified_cop_name('NotACop', '') # => 'NotACop'
      #
      # @param name [String] Cop name extracted from config
      # @param path [String, nil] Path of file that `name` was extracted from
      # @param warn [Boolean] Print a warning if no department given for `name`
      #
      # @raise [AmbiguousCopName]
      #   if a bare identifier with two possible namespaces is provided
      #
      # @note Emits a warning if the provided name has an incorrect namespace
      #
      # @return [String] Qualified cop name
      def qualified_cop_name(name, path, warn: true)
        badge = Badge.parse(name)
        print_warning(name, path) if warn && department_missing?(badge, name)
        return name if registered?(badge)

        potential_badges = qualify_badge(badge)

        case potential_badges.size
        when 0 then name # No namespace found. Deal with it later in caller.
        when 1 then resolve_badge(badge, potential_badges.first, path, warn: warn)
        else raise AmbiguousCopName.new(badge, path, potential_badges)
        end
      end

      def department_missing?(badge, name)
        !badge.qualified? && unqualified_cop_names.include?(name)
      end

      def print_warning(name, path)
        message = "#{path}: Warning: no department given for #{name}."
        if path.end_with?('.rb')
          message += ' Run `rubocop -a --only Migration/DepartmentName` to fix.'
        end
        warn message
      end

      def unqualified_cop_names
        clear_enrollment_queue
        @unqualified_cop_names ||=
          Set.new(@cops_by_cop_name.keys.map { |qn| File.basename(qn) }) <<
          'RedundantCopDisableDirective'
      end

      def qualify_badge(badge)
        clear_enrollment_queue
        @departments
          .map { |department, _| badge.with_department(department) }
          .select { |potential_badge| registered?(potential_badge) }
      end

      # @return [Hash{String => Array<Class>}]
      def to_h
        clear_enrollment_queue
        @cops_by_cop_name
      end

      def cops
        clear_enrollment_queue
        @registry.values
      end

      def length
        clear_enrollment_queue
        @registry.size
      end

      def enabled(config)
        @enabled_cache[config] ||= select { |cop| enabled?(cop, config) }
      end

      def disabled(config)
        @disabled_cache[config] ||= reject { |cop| enabled?(cop, config) }
      end

      def enabled?(cop, config)
        return true if options[:only]&.include?(cop.cop_name)

        # We need to use `cop_name` in this case, because `for_cop` uses caching
        # which expects cop names or cop classes as keys.
        cfg = config.for_cop(cop.cop_name)

        cop_enabled = cfg.fetch('Enabled') == true || enabled_pending_cop?(cfg, config)

        if options.fetch(:safe, false)
          cop_enabled && cfg.fetch('Safe', true)
        else
          cop_enabled
        end
      end

      def enabled_pending_cop?(cop_cfg, config)
        return false if @options[:disable_pending_cops]

        cop_cfg.fetch('Enabled') == 'pending' &&
          (@options[:enable_pending_cops] || config.enabled_new_cops?)
      end

      def names
        cops.map(&:cop_name)
      end

      def cops_for_department(department)
        cops.select { |cop| cop.department == department.to_sym }
      end

      def names_for_department(department)
        cops_for_department(department).map(&:cop_name)
      end

      def ==(other)
        cops == other.cops
      end

      def sort!
        clear_enrollment_queue
        @registry = @registry.sort_by { |badge, _| badge.cop_name }.to_h

        self
      end

      def select(&block)
        cops.select(&block)
      end

      def each(&block)
        cops.each(&block)
      end

      # @param [String] cop_name
      # @return [Class, nil]
      def find_by_cop_name(cop_name)
        to_h[cop_name].first
      end

      # When a cop name is given returns a single-element array with the cop class.
      # When a department name is given returns an array with all the cop classes
      # for that department.
      def find_cops_by_directive(directive)
        cop = find_by_cop_name(directive)
        cop ? [cop] : cops_for_department(directive)
      end

      def freeze
        clear_enrollment_queue
        unqualified_cop_names # build cache
        super
      end

      @global = new

      class << self
        attr_reader :global
      end

      private

      def initialize_copy(reg)
        initialize(reg.cops, reg.options)
      end

      def clear_enrollment_queue
        return if @enrollment_queue.empty?

        @enrollment_queue.each do |cop|
          @registry[cop.badge] = cop
          @departments[cop.department] ||= []
          @departments[cop.department] << cop
          @cops_by_cop_name[cop.cop_name] << cop
        end
        @enrollment_queue = []
      end

      def with(cops)
        self.class.new(cops)
      end

      def resolve_badge(given_badge, real_badge, source_path, warn: true)
        unless given_badge.match?(real_badge)
          path = PathUtil.smart_path(source_path)

          if warn
            warn("#{path}: #{given_badge} has the wrong namespace - " \
                 "replace it with #{given_badge.with_department(real_badge.department)}")
          end
        end

        real_badge.to_s
      end

      def registered?(badge)
        clear_enrollment_queue
        @registry.key?(badge)
      end
    end
  end
end
