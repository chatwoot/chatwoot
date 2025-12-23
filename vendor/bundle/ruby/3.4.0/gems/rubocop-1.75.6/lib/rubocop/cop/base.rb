# frozen_string_literal: true

module RuboCop
  module Cop
    # A scaffold for concrete cops.
    #
    # The Cop::Base class is meant to be extended.
    #
    # Cops track offenses and can autocorrect them on the fly.
    #
    # A commissioner object is responsible for traversing the AST and invoking
    # the specific callbacks on each cop.
    #
    # First the callback `on_new_investigation` is called;
    # if a cop needs to do its own processing of the AST or depends on
    # something else.
    #
    # Then callbacks like `on_def`, `on_send` (see AST::Traversal) are called
    # with their respective nodes.
    #
    # Finally the callback `on_investigation_end` is called.
    #
    # Within these callbacks, cops are meant to call `add_offense` or
    # `add_global_offense`. Use the `processed_source` method to
    # get the currently processed source being investigated.
    #
    # In case of invalid syntax / unparsable content,
    # the callback `on_other_file` is called instead of all the other
    # `on_...` callbacks.
    #
    # Private methods are not meant for custom cops consumption,
    # nor are any instance variables.
    #
    class Base # rubocop:disable Metrics/ClassLength
      extend RuboCop::AST::Sexp
      extend NodePattern::Macros
      extend ExcludeLimit
      include RuboCop::AST::Sexp
      include Util
      include IgnoredNode
      include AutocorrectLogic

      attr_reader :config, :processed_source

      # Reports of an investigation.
      # Immutable
      # Consider creation API private
      InvestigationReport = Struct.new(:cop, :processed_source, :offenses, :corrector)

      # List of methods names to restrict calls for `on_send` / `on_csend`
      RESTRICT_ON_SEND = Set[].freeze # rubocop:disable InternalAffairs/UselessRestrictOnSend

      # List of cops that should not try to autocorrect at the same
      # time as this cop
      #
      # @return [Array<RuboCop::Cop::Base>]
      #
      # @api public
      def self.autocorrect_incompatible_with
        []
      end

      # Returns a url to view this cops documentation online.
      # Requires 'DocumentationBaseURL' to be set for your department.
      # Will follow the convention of RuboCops own documentation structure,
      # overwrite this method to accommodate your custom layout.
      # @return [String, nil]
      #
      # @api public
      def self.documentation_url(config = nil)
        Documentation.url_for(self, config)
      end

      def self.inherited(subclass)
        super
        subclass.instance_variable_set(:@gem_requirements, gem_requirements.dup)
        Registry.global.enlist(subclass)
      end

      # Call for abstract Cop classes
      def self.exclude_from_registry
        Registry.global.dismiss(self)
      end

      # Returns if class supports autocorrect.
      # It is recommended to extend AutoCorrector instead of overriding
      def self.support_autocorrect?
        false
      end

      ### Naming

      def self.badge
        @badge ||= Badge.for(name)
      end

      def self.cop_name
        badge.to_s
      end

      def self.department
        badge.department
      end

      def self.lint?
        department == :Lint
      end

      # Returns true if the cop name or the cop namespace matches any of the
      # given names.
      def self.match?(given_names)
        return false unless given_names

        given_names.include?(cop_name) || given_names.include?(badge.department_name)
      end

      # Override and return the Force class(es) you need to join
      def self.joining_forces; end

      ### Persistence

      # Override if your cop should be called repeatedly for multiple investigations
      # Between calls to `on_new_investigation` and `on_investigation_end`,
      # the result of `processed_source` will remain constant.
      # You should invalidate any caches that depend on the current `processed_source`
      # in the `on_new_investigation` callback.
      # If your cop does autocorrections, be aware that your instance may be called
      # multiple times with the same `processed_source.path` but different content.
      def self.support_multiple_source?
        false
      end

      ## Gem requirements

      @gem_requirements = {}

      class << self
        attr_reader :gem_requirements

        # Register a version requirement for the given gem name.
        # This cop will be skipped unless the target satisfies *all* requirements.
        # @param [String] gem_name
        # @param [Array<String>] version_requirements The version requirements,
        #   using the same syntax as a Gemfile, e.g. ">= 1.2.3"
        #
        #   If omitted, any version of the gem will be accepted.
        #
        #   https://guides.rubygems.org/patterns/#declaring-dependencies
        #
        # @api public
        def requires_gem(gem_name, *version_requirements)
          @gem_requirements[gem_name] = Gem::Requirement.new(version_requirements)
        end
      end

      def initialize(config = nil, options = nil)
        @config = config || Config.new
        @options = options || { debug: false }
        reset_investigation
      end

      # Called before all on_... have been called
      # When refining this method, always call `super`
      def on_new_investigation
        # Typically do nothing here
      end

      # Called after all on_... have been called
      # When refining this method, always call `super`
      def on_investigation_end
        # Typically do nothing here
      end

      # Called instead of all on_... callbacks for unrecognized files / syntax errors
      # When refining this method, always call `super`
      def on_other_file
        # Typically do nothing here
      end

      # Gets called if no message is specified when calling `add_offense` or
      # `add_global_offense`
      # Cops are discouraged to override this; instead pass your message directly
      def message(_range = nil)
        self.class::MSG
      end

      # Adds an offense that has no particular location.
      # No correction can be applied to global offenses
      def add_global_offense(message = nil, severity: nil)
        severity = find_severity(nil, severity)
        message = find_message(nil, message)
        range = Offense::NO_LOCATION
        status = enabled_line?(range.line) ? :unsupported : :disabled
        current_offenses << Offense.new(severity, range, message, name, status)
      end

      # Adds an offense on the specified range (or node with an expression)
      # Unless that offense is disabled for this range, a corrector will be yielded
      # to provide the cop the opportunity to autocorrect the offense.
      # If message is not specified, the method `message` will be called.
      def add_offense(node_or_range, message: nil, severity: nil, &block)
        range = range_from_node_or_range(node_or_range)
        return unless current_offense_locations.add?(range)

        range_to_pass = callback_argument(range)

        severity = find_severity(range_to_pass, severity)
        message = find_message(range_to_pass, message)

        status, corrector = enabled_line?(range.line) ? correct(range, &block) : :disabled

        # Since this range may be generated from Ruby code embedded in some
        # template file, we convert it to location info in the original file.
        range = range_for_original(range)

        current_offenses << Offense.new(severity, range, message, name, status, corrector)
      end

      # This method should be overridden when a cop's behavior depends
      # on state that lives outside of these locations:
      #
      #   (1) the file under inspection
      #   (2) the cop's source code
      #   (3) the config (eg a .rubocop.yml file)
      #
      # For example, some cops may want to look at other parts of
      # the codebase being inspected to find violations. A cop may
      # use the presence or absence of file `foo.rb` to determine
      # whether a certain violation exists in `bar.rb`.
      #
      # Overriding this method allows the cop to indicate to RuboCop's
      # ResultCache system when those external dependencies change,
      # ie when the ResultCache should be invalidated.
      def external_dependency_checksum
        nil
      end

      def cop_name
        @cop_name ||= self.class.cop_name
      end

      alias name cop_name

      ### Configuration Helpers

      def cop_config
        # Use department configuration as basis, but let individual cop
        # configuration override.
        @cop_config ||= @config.for_badge(self.class.badge)
      end

      def config_to_allow_offenses
        Formatter::DisabledConfigFormatter.config_to_allow_offenses[cop_name] ||= {}
      end

      def config_to_allow_offenses=(hash)
        Formatter::DisabledConfigFormatter.config_to_allow_offenses[cop_name] = hash
      end

      def target_ruby_version
        @config.target_ruby_version
      end

      # Returns a gems locked versions (i.e. from Gemfile.lock or gems.locked)
      # @returns [Gem::Version | nil] The locked gem version, or nil if the gem is not present.
      def target_gem_version(gem_name)
        @config.gem_versions_in_target && @config.gem_versions_in_target[gem_name]
      end

      def parser_engine
        @config.parser_engine
      end

      def target_rails_version
        @config.target_rails_version
      end

      def active_support_extensions_enabled?
        @config.active_support_extensions_enabled?
      end

      def string_literals_frozen_by_default?
        @config.string_literals_frozen_by_default?
      end

      def relevant_file?(file)
        return false unless target_satisfies_all_gem_version_requirements?
        return true unless @config.clusivity_config_for_badge?(self.class.badge)

        file == RuboCop::AST::ProcessedSource::STRING_SOURCE_NAME ||
          (file_name_matches_any?(file, 'Include', true) &&
            !file_name_matches_any?(file, 'Exclude', false))
      end

      def excluded_file?(file)
        !relevant_file?(file)
      end

      # There should be very limited reasons for a Cop to do it's own parsing
      def parse(source, path = nil)
        ProcessedSource.new(source, target_ruby_version, path, parser_engine: parser_engine)
      end

      # @api private
      # Called between investigations
      def ready
        return self if self.class.support_multiple_source?

        self.class.new(@config, @options)
      end

      ### Reserved for Cop::Cop

      # @deprecated Make potential errors with previous API more obvious
      def offenses
        raise 'The offenses are not directly available; ' \
              'they are returned as the result of the investigation'
      end

      ### Reserved for Commissioner

      # rubocop:disable Layout/ClassStructure
      # @api private
      def callbacks_needed
        self.class.callbacks_needed
      end

      # @api private
      def self.callbacks_needed
        @callbacks_needed ||= public_instance_methods.select do |m|
          # OPTIMIZE: Check method existence first to make fewer `start_with?` calls.
          # At the time of writing this comment, this excludes 98 of ~104 methods.
          # `start_with?` with two string arguments instead of a regex is faster
          # in this specific case as well.
          !Base.method_defined?(m) && # exclude standard "callbacks" like 'on_begin_investigation'
            m.start_with?('on_', 'after_')
        end
      end
      # rubocop:enable Layout/ClassStructure

      # Called before any investigation
      # @api private
      def begin_investigation(processed_source, offset: 0, original: processed_source)
        @current_offenses = nil
        @current_offense_locations = nil
        @currently_disabled_lines = nil
        @processed_source = processed_source
        @current_corrector = nil

        # We need to keep track of the original source and offset,
        # because `processed_source` here may be an embedded code in it.
        @current_offset = offset
        @current_original = original
      end

      # @api private
      def always_autocorrect?
        # `true` is the same as `'always'` for backward compatibility.
        ['always', true].include?(cop_config.fetch('AutoCorrect', 'always'))
      end

      # @api private
      def contextual_autocorrect?
        cop_config.fetch('AutoCorrect', 'always') == 'contextual'
      end

      def inspect # :nodoc:
        "#<#{self.class.name}:#{object_id} @config=#{@config} @options=#{@options}>"
      end

      private

      ### Reserved for Cop::Cop

      def callback_argument(range)
        range
      end

      def apply_correction(corrector)
        current_corrector&.merge!(corrector) if corrector
      end

      ### Reserved for Commissioner:

      def current_offense_locations
        @current_offense_locations ||= Set.new
      end

      def currently_disabled_lines
        @currently_disabled_lines ||= Set.new
      end

      def current_corrector
        @current_corrector ||= Corrector.new(@processed_source) if @processed_source.valid_syntax?
      end

      def current_offenses
        @current_offenses ||= []
      end

      private_class_method def self.restrict_on_send
        @restrict_on_send ||= self::RESTRICT_ON_SEND.to_a.freeze
      end

      EMPTY_OFFENSES = [].freeze
      private_constant :EMPTY_OFFENSES
      # Called to complete an investigation
      def complete_investigation
        InvestigationReport.new(
          self, processed_source, @current_offenses || EMPTY_OFFENSES, @current_corrector
        )
      ensure
        reset_investigation
      end

      ### Actually private methods

      def reset_investigation
        @currently_disabled_lines = @current_offenses = @processed_source = @current_corrector = nil
      end

      # @return [Symbol, Corrector] offense status
      def correct(range)
        if block_given?
          corrector = Corrector.new(self)
          yield corrector
          if corrector.empty?
            corrector = nil
          elsif !self.class.support_autocorrect?
            raise "The Cop #{name} must `extend AutoCorrector` to be able to autocorrect"
          end
        end

        [use_corrector(range, corrector), corrector]
      end

      # @return [Symbol] offense status
      def use_corrector(range, corrector)
        if autocorrect?
          attempt_correction(range, corrector)
        elsif corrector && (always_autocorrect? || (contextual_autocorrect? && !LSP.enabled?))
          :uncorrected
        else
          :unsupported
        end
      end

      # @return [Symbol] offense status
      def attempt_correction(range, corrector)
        if corrector
          status = :corrected
        elsif disable_uncorrectable?
          corrector = disable_uncorrectable(range)
          status = :corrected_with_todo
        else
          return :unsupported
        end

        apply_correction(corrector)
        status
      end

      def disable_uncorrectable(range)
        line = range.line
        return unless currently_disabled_lines.add?(line)

        disable_offense(range)
      end

      def range_from_node_or_range(node_or_range)
        if node_or_range.respond_to?(:loc)
          node_or_range.source_range
        elsif node_or_range.is_a?(::Parser::Source::Range)
          node_or_range
        else
          extra = ' (call `add_global_offense`)' if node_or_range.nil?
          raise "Expected a Source::Range, got #{node_or_range.inspect}#{extra}"
        end
      end

      def find_message(range, message)
        annotate(message || message(range))
      end

      def annotate(message)
        RuboCop::Cop::MessageAnnotator.new(
          config, cop_name, cop_config, @options
        ).annotate(message)
      end

      def file_name_matches_any?(file, parameter, default_result)
        patterns = cop_config[parameter]
        return default_result unless patterns

        patterns = FilePatterns.from(patterns)
        patterns.match?(config.path_relative_to_config(file)) || patterns.match?(file)
      end

      def enabled_line?(line_number)
        return true if @options[:ignore_disable_comments] || !@processed_source

        @processed_source.comment_config.cop_enabled_at_line?(self, line_number)
      end

      def find_severity(_range, severity)
        custom_severity || severity || default_severity
      end

      def default_severity
        self.class.lint? ? :warning : :convention
      end

      def custom_severity
        severity = cop_config['Severity']
        return unless severity

        if Severity::NAMES.include?(severity.to_sym)
          severity.to_sym
        else
          message = "Warning: Invalid severity '#{severity}'. " \
                    "Valid severities are #{Severity::NAMES.join(', ')}."
          warn(Rainbow(message).red)
        end
      end

      def range_for_original(range)
        ::Parser::Source::Range.new(
          @current_original.buffer,
          range.begin_pos + @current_offset,
          range.end_pos + @current_offset
        )
      end

      def target_satisfies_all_gem_version_requirements?
        self.class.gem_requirements.all? do |gem_name, version_req|
          all_gem_versions_in_target = @config.gem_versions_in_target
          next false unless all_gem_versions_in_target

          gem_version_in_target = all_gem_versions_in_target[gem_name]
          next false unless gem_version_in_target

          version_req.satisfied_by?(gem_version_in_target)
        end
      end
    end
  end
end
