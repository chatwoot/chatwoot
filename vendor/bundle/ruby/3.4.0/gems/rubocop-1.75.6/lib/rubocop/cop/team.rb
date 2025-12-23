# frozen_string_literal: true

module RuboCop
  module Cop
    # A group of cops, ready to be called on duty to inspect files.
    # Team is responsible for selecting only relevant cops to be sent on duty,
    # as well as insuring that the needed forces are sent along with them.
    #
    # For performance reasons, Team will first dispatch cops & forces in two groups,
    # first the ones needed for autocorrection (if any), then the rest
    # (unless autocorrections happened).
    # rubocop:disable Metrics/ClassLength
    class Team
      # @return [Team]
      def self.new(cop_or_classes, config, options = {})
        # Support v0 api:
        if cop_or_classes.first.is_a?(Class)
          warn Rainbow(<<~WARNING).yellow, uplevel: 1
            `Team.new` with cop classes is deprecated. Use `Team.mobilize` instead.
          WARNING
          return mobilize(cop_or_classes, config, options)
        end

        super
      end

      # @return [Team] with cops assembled from the given `cop_classes`
      def self.mobilize(cop_classes, config, options = {})
        cops = mobilize_cops(cop_classes, config, options)
        new(cops, config, options)
      end

      # @return [Array<Cop::Base>]
      def self.mobilize_cops(cop_classes, config, options = {})
        cop_classes = Registry.new(cop_classes.to_a, options) unless cop_classes.is_a?(Registry)

        cop_classes.map do |cop_class|
          cop_class.new(config, options)
        end
      end

      # @return [Array<Force>] needed for the given cops
      def self.forces_for(cops)
        needed = Hash.new { |h, k| h[k] = [] }
        cops.each do |cop|
          forces = cop.class.joining_forces
          if forces.is_a?(Array)
            forces.each { |force| needed[force] << cop }
          elsif forces
            needed[forces] << cop
          end
        end

        needed.map { |force_class, joining_cops| force_class.new(joining_cops) }
      end

      attr_reader :errors, :warnings, :updated_source_file, :cops

      alias updated_source_file? updated_source_file

      def initialize(cops, config = nil, options = {})
        @cops = cops
        @config = config
        @options = options
        reset
        @ready = true
        @registry = Registry.new(cops, options.dup)

        validate_config
      end

      def autocorrect?
        @options[:autocorrect]
      end

      def debug?
        @options[:debug]
      end

      # @deprecated. Use investigate
      # @return Array<offenses>
      def inspect_file(processed_source)
        warn Rainbow(<<~WARNING).yellow, uplevel: 1
          `inspect_file` is deprecated. Use `investigate` instead.
        WARNING

        investigate(processed_source).offenses
      end

      # @return [Commissioner::InvestigationReport]
      def investigate(processed_source, offset: 0, original: processed_source)
        be_ready

        # The autocorrection process may have to be repeated multiple times
        # until there are no corrections left to perform
        # To speed things up, run autocorrecting cops by themselves, and only
        # run the other cops when no corrections are left
        on_duty = roundup_relevant_cops(processed_source)

        autocorrect_cops, other_cops = on_duty.partition(&:autocorrect?)
        report = investigate_partial(autocorrect_cops, processed_source,
                                     offset: offset, original: original)

        unless autocorrect(processed_source, report, offset: offset, original: original)
          # If we corrected some errors, another round of inspection will be
          # done, and any other offenses will be caught then, so only need
          # to check other_cops if no correction was done
          report = report.merge(investigate_partial(other_cops, processed_source,
                                                    offset: offset, original: original))
        end

        process_errors(processed_source.path, report.errors)

        report
      ensure
        @ready = false
      end

      # @deprecated
      def forces
        warn Rainbow(<<~WARNING).yellow, uplevel: 1
          `forces` is deprecated.
        WARNING

        @forces ||= self.class.forces_for(cops)
      end

      def external_dependency_checksum
        # The external dependency checksums are cached per RuboCop team so that
        # the checksums don't need to be recomputed for each file.
        @external_dependency_checksum ||= begin
          keys = cops.filter_map(&:external_dependency_checksum)
          Digest::SHA1.hexdigest(keys.join)
        end
      end

      private

      def autocorrect(processed_source, report, original:, offset:)
        @updated_source_file = false
        return unless autocorrect?
        return if report.processed_source.parser_error

        new_source = autocorrect_report(report, original: original, offset: offset)

        return unless new_source

        if @options[:stdin]
          # holds source read in from stdin, when --stdin option is used
          @options[:stdin] = new_source
        else
          filename = processed_source.file_path
          File.write(filename, new_source)
        end
        @updated_source_file = true
      end

      def be_ready
        return if @ready

        reset
        @cops.map!(&:ready)
        @ready = true
      end

      def reset
        @errors = []
        @warnings = []
      end

      # @return [Commissioner::InvestigationReport]
      def investigate_partial(cops, processed_source, offset:, original:)
        commissioner = Commissioner.new(cops, self.class.forces_for(cops), @options)
        commissioner.investigate(processed_source, offset: offset, original: original)
      end

      # @return [Array<cop>]
      def roundup_relevant_cops(processed_source)
        cops.select do |cop|
          next true if processed_source.comment_config.cop_opted_in?(cop)
          next false if cop.excluded_file?(processed_source.file_path)
          next false unless @registry.enabled?(cop, @config)

          support_target_ruby_version?(cop) && support_target_rails_version?(cop)
        end
      end

      def support_target_ruby_version?(cop)
        return true unless cop.class.respond_to?(:support_target_ruby_version?)

        cop.class.support_target_ruby_version?(cop.target_ruby_version)
      end

      def support_target_rails_version?(cop)
        # In this case, the rails version was already checked by `#excluded_file?`
        return true if defined?(RuboCop::Rails::TargetRailsVersion::USES_REQUIRES_GEM_API)

        return true unless cop.class.respond_to?(:support_target_rails_version?)

        cop.class.support_target_rails_version?(cop.target_rails_version)
      end

      def autocorrect_report(report, offset:, original:)
        corrector = collate_corrections(report, offset: offset, original: original)

        corrector.rewrite unless corrector.empty?
      end

      def collate_corrections(report, offset:, original:)
        corrector = Corrector.new(original)

        each_corrector(report) do |to_merge|
          suppress_clobbering do
            if offset.positive?
              corrector.import!(to_merge, offset: offset)
            else
              corrector.merge!(to_merge)
            end
          end
        end

        corrector
      end

      def each_corrector(report)
        skips = Set.new
        report.cop_reports.each do |cop_report|
          cop = cop_report.cop
          corrector = cop_report.corrector

          next if corrector.nil? || corrector.empty?
          next if skips.include?(cop.class)

          yield corrector

          skips.merge(cop.class.autocorrect_incompatible_with)
        end
      end

      def suppress_clobbering
        yield
      rescue ::Parser::ClobberingError
        # ignore Clobbering errors
      end

      def validate_config
        cops.each do |cop|
          cop.validate_config if cop.respond_to?(:validate_config)
        end
      end

      def process_errors(file, errors)
        errors.each do |error|
          line = ":#{error.line}" if error.line
          column = ":#{error.column}" if error.column
          location = "#{file}#{line}#{column}"
          cause = error.cause

          if cause.is_a?(Warning)
            handle_warning(cause, location)
          elsif cause.is_a?(Force::HookError)
            handle_error(cause.cause, location, cause.joining_cop)
          else
            handle_error(cause, location, error.cop)
          end
        end
      end

      def handle_warning(error, location)
        message = Rainbow("#{error.message} (from file: #{location})").yellow

        @warnings << message
        warn message
        puts error.backtrace if debug?
      end

      def handle_error(error, location, cop)
        message = Rainbow("An error occurred while #{cop.name} cop was inspecting #{location}.").red
        @errors << message
        warn message
        if debug?
          puts error.message, error.backtrace
        else
          warn 'To see the complete backtrace run rubocop -d.'
        end
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
