# frozen_string_literal: true

require 'parallel'

module RuboCop
  # This class handles the processing of files, which includes dealing with
  # formatters and letting cops inspect the files.
  class Runner # rubocop:disable Metrics/ClassLength
    # An exception indicating that the inspection loop got stuck correcting
    # offenses back and forth.
    class InfiniteCorrectionLoop < StandardError
      attr_reader :offenses

      def initialize(path, offenses_by_iteration, loop_start: -1)
        @offenses = offenses_by_iteration.flatten.uniq
        root_cause = offenses_by_iteration[loop_start..]
                     .map { |x| x.map(&:cop_name).uniq.join(', ') }
                     .join(' -> ')

        message = 'Infinite loop detected'
        message += " in #{path}" if path
        message += " and caused by #{root_cause}" if root_cause
        super(message)
      end
    end

    class << self
      # @return [Array<#call>]
      def ruby_extractors
        @ruby_extractors ||= [default_ruby_extractor]
      end

      private

      # @return [#call]
      def default_ruby_extractor
        lambda do |processed_source|
          [
            {
              offset: 0,
              processed_source: processed_source
            }
          ]
        end
      end
    end

    # @api private
    MAX_ITERATIONS = 200

    # @api private
    REDUNDANT_COP_DISABLE_DIRECTIVE_RULES = %w[
      Lint/RedundantCopDisableDirective RedundantCopDisableDirective Lint
    ].freeze

    attr_reader :errors, :warnings
    attr_writer :aborting

    def initialize(options, config_store)
      @options = options
      @config_store = config_store
      @errors = []
      @warnings = []
      @aborting = false
    end

    def run(paths)
      target_files = find_target_files(paths)
      if @options[:list_target_files]
        list_files(target_files)
      else
        warm_cache(target_files) if @options[:parallel]
        inspect_files(target_files)
      end
    rescue Interrupt
      self.aborting = true
      warn ''
      warn 'Exiting...'

      false
    end

    def aborting?
      @aborting
    end

    private

    # Warms up the RuboCop cache by forking a suitable number of RuboCop
    # instances that each inspects its allotted group of files.
    def warm_cache(target_files)
      saved_options = @options.dup
      if target_files.length <= 1
        puts 'Skipping parallel inspection: only a single file needs inspection' if @options[:debug]
        return
      end
      puts 'Running parallel inspection' if @options[:debug]
      %i[autocorrect safe_autocorrect].each { |opt| @options[opt] = false }
      Parallel.each(target_files) { |target_file| file_offenses(target_file) }
    ensure
      @options = saved_options
    end

    def find_target_files(paths)
      target_finder = TargetFinder.new(@config_store, @options)
      mode = if @options[:only_recognized_file_types]
               :only_recognized_file_types
             else
               :all_file_types
             end
      target_files = target_finder.find(paths, mode)
      target_files.each(&:freeze).freeze
    end

    def inspect_files(files)
      inspected_files = []

      formatter_set.started(files)

      each_inspected_file(files) { |file| inspected_files << file }
    ensure
      # OPTIMIZE: Calling `ResultCache.cleanup` takes time. This optimization
      # mainly targets editors that integrates RuboCop. When RuboCop is run
      # by an editor, it should be inspecting only one file.
      if files.size > 1 && cached_run?
        ResultCache.cleanup(@config_store, @options[:debug], @options[:cache_root])
      end

      formatter_set.finished(inspected_files.freeze)
      formatter_set.close_output_files
    end

    def each_inspected_file(files)
      files.reduce(true) do |all_passed, file|
        offenses = process_file(file)
        yield file

        if offenses.any? { |o| considered_failure?(o) && offense_displayed?(o) }
          break false if @options[:fail_fast]

          next false
        end

        all_passed
      end
    end

    def list_files(paths)
      paths.each { |path| puts PathUtil.relative_path(path) }
    end

    def process_file(file)
      file_started(file)
      offenses = file_offenses(file)
    rescue InfiniteCorrectionLoop => e
      raise e if @options[:raise_cop_error]

      errors << e
      warn Rainbow(e.message).red
      offenses = e.offenses.compact.sort.freeze
    ensure
      file_finished(file, offenses || [])
    end

    def file_offenses(file)
      file_offense_cache(file) do
        source, offenses = do_inspection_loop(file)
        offenses = add_redundant_disables(file, offenses.compact.sort, source)
        offenses.sort.reject(&:disabled?).freeze
      end
    end

    def cached_result(file, team)
      ResultCache.new(file, team, @options, @config_store)
    end

    def file_offense_cache(file)
      config = @config_store.for_file(file)
      cache = cached_result(file, standby_team(config)) if cached_run?

      if cache&.valid?
        offenses = cache.load
        # If we're running --autocorrect and the cache says there are
        # offenses, we need to actually inspect the file. If the cache shows no
        # offenses, we're good.
        real_run_needed = @options[:autocorrect] && offenses.any?
      else
        real_run_needed = true
      end

      if real_run_needed
        offenses = yield
        save_in_cache(cache, offenses)
      end

      offenses
    end

    def add_redundant_disables(file, offenses, source)
      team_for_redundant_disables(file, offenses, source) do |team|
        new_offenses, redundant_updated = inspect_file(source, team)
        offenses += new_offenses
        if redundant_updated
          # Do one extra inspection loop if any redundant disables were
          # removed. This is done in order to find rubocop:enable directives that
          # have now become useless.
          _source, new_offenses = do_inspection_loop(file)
          offenses |= new_offenses
        end
      end
      offenses
    end

    def team_for_redundant_disables(file, offenses, source)
      return unless check_for_redundant_disables?(source)

      config = @config_store.for_file(file)
      team = Cop::Team.mobilize([Cop::Lint::RedundantCopDisableDirective], config, @options)
      return if team.cops.empty?

      team.cops.first.offenses_to_check = offenses
      yield team
    end

    def check_for_redundant_disables?(source)
      return false if source.disabled_line_ranges.empty? || except_redundant_cop_disable_directive?

      !@options[:only]
    end

    def redundant_cop_disable_directive(file)
      config = @config_store.for_file(file)
      return unless config.for_cop(Cop::Lint::RedundantCopDisableDirective).fetch('Enabled')

      cop = Cop::Lint::RedundantCopDisableDirective.new(config, @options)
      yield cop if cop.relevant_file?(file)
    end

    def except_redundant_cop_disable_directive?
      @options[:except] && (@options[:except] & REDUNDANT_COP_DISABLE_DIRECTIVE_RULES).any?
    end

    def file_started(file)
      puts "Scanning #{file}" if @options[:debug]
      formatter_set.file_started(file, cli_options: @options, config_store: @config_store)
    end

    def file_finished(file, offenses)
      offenses = offenses_to_report(offenses)
      formatter_set.file_finished(file, offenses)
    end

    def cached_run?
      @cached_run ||=
        (@options[:cache] == 'true' ||
         (@options[:cache] != 'false' && @config_store.for_pwd.for_all_cops['UseCache'])) &&
        # When running --auto-gen-config, there's some processing done in the
        # cops related to calculating the Max parameters for Metrics cops. We
        # need to do that processing and cannot use caching.
        !@options[:auto_gen_config] &&
        # We can't cache results from code which is piped in to stdin
        !@options[:stdin]
    end

    def save_in_cache(cache, offenses)
      return unless cache
      # Caching results when a cop has crashed would prevent the crash in the
      # next run, since the cop would not be called then. We want crashes to
      # show up the same in each run.
      return if errors.any? || warnings.any?

      cache.save(offenses)
    end

    def do_inspection_loop(file)
      processed_source = get_processed_source(file)
      # This variable is 2d array used to track corrected offenses after each
      # inspection iteration. This is used to output meaningful infinite loop
      # error message.
      offenses_by_iteration = []

      # When running with --autocorrect, we need to inspect the file (which
      # includes writing a corrected version of it) until no more corrections
      # are made. This is because automatic corrections can introduce new
      # offenses. In the normal case the loop is only executed once.
      iterate_until_no_changes(processed_source, offenses_by_iteration) do
        # The offenses that couldn't be corrected will be found again so we
        # only keep the corrected ones in order to avoid duplicate reporting.
        !offenses_by_iteration.empty? && offenses_by_iteration.last.select!(&:corrected?)
        new_offenses, updated_source_file = inspect_file(processed_source)
        offenses_by_iteration.push(new_offenses)

        # We have to reprocess the source to pickup the changes. Since the
        # change could (theoretically) introduce parsing errors, we break the
        # loop if we find any.
        break unless updated_source_file

        processed_source = get_processed_source(file)
      end

      # Return summary of corrected offenses after all iterations
      offenses = offenses_by_iteration.flatten.uniq
      [processed_source, offenses]
    end

    def iterate_until_no_changes(source, offenses_by_iteration)
      # Keep track of the state of the source. If a cop modifies the source
      # and another cop undoes it producing identical source we have an
      # infinite loop.
      @processed_sources = []

      # It is also possible for a cop to keep adding indefinitely to a file,
      # making it bigger and bigger. If the inspection loop runs for an
      # excessively high number of iterations, this is likely happening.
      iterations = 0

      loop do
        check_for_infinite_loop(source, offenses_by_iteration)

        if (iterations += 1) > MAX_ITERATIONS
          raise InfiniteCorrectionLoop.new(source.path, offenses_by_iteration)
        end

        source = yield
        break unless source
      end
    end

    # Check whether a run created source identical to a previous run, which
    # means that we definitely have an infinite loop.
    def check_for_infinite_loop(processed_source, offenses_by_iteration)
      checksum = processed_source.checksum

      if (loop_start_index = @processed_sources.index(checksum))
        raise InfiniteCorrectionLoop.new(
          processed_source.path,
          offenses_by_iteration,
          loop_start: loop_start_index
        )
      end

      @processed_sources << checksum
    end

    def inspect_file(processed_source, team = mobilize_team(processed_source))
      extracted_ruby_sources = extract_ruby_sources(processed_source)
      offenses = extracted_ruby_sources.flat_map do |extracted_ruby_source|
        report = team.investigate(
          extracted_ruby_source[:processed_source],
          offset: extracted_ruby_source[:offset],
          original: processed_source
        )
        @errors.concat(team.errors)
        @warnings.concat(team.warnings)
        report.offenses
      end
      [offenses, team.updated_source_file?]
    end

    def extract_ruby_sources(processed_source)
      self.class.ruby_extractors.find do |ruby_extractor|
        result = ruby_extractor.call(processed_source)
        break result if result
      rescue StandardError
        location = if ruby_extractor.is_a?(Proc)
                     ruby_extractor.source_location
                   else
                     ruby_extractor.method(:call).source_location
                   end
        raise Error, "Ruby extractor #{location[0]} failed to process #{processed_source.path}."
      end
    end

    def mobilize_team(processed_source)
      config = @config_store.for_file(processed_source.path)
      Cop::Team.mobilize(mobilized_cop_classes(config), config, @options)
    end

    def mobilized_cop_classes(config) # rubocop:disable Metrics/AbcSize
      @mobilized_cop_classes ||= {}.compare_by_identity
      @mobilized_cop_classes[config] ||= begin
        cop_classes = Cop::Registry.all

        # `@options[:only]` and `@options[:except]` are not qualified until
        # needed so that the Registry can be fully loaded, including any
        # cops added by `require`s.
        qualify_option_cop_names

        OptionsValidator.new(@options).validate_cop_options

        if @options[:only]
          cop_classes.select! { |c| c.match?(@options[:only]) }
        else
          filter_cop_classes(cop_classes, config)
        end

        cop_classes.reject! { |c| c.match?(@options[:except]) }

        Cop::Registry.new(cop_classes, @options)
      end
    end

    def qualify_option_cop_names
      %i[only except].each do |option|
        next unless @options[option]

        @options[option].map! do |cop_name|
          Cop::Registry.qualified_cop_name(cop_name, "--#{option} option")
        end
      end
    end

    def filter_cop_classes(cop_classes, config)
      # use only cops that link to a style guide if requested
      return unless style_guide_cops_only?(config)

      cop_classes.select! { |cop| config.for_cop(cop)['StyleGuide'] }
    end

    def style_guide_cops_only?(config)
      @options[:only_guide_cops] || config.for_all_cops['StyleGuideCopsOnly']
    end

    def formatter_set
      @formatter_set ||= begin
        set = Formatter::FormatterSet.new(@options)
        pairs = @options[:formatters] || [['progress']]
        pairs.each { |formatter_key, output_path| set.add_formatter(formatter_key, output_path) }
        set
      end
    end

    def considered_failure?(offense)
      return false if offense.disabled?

      # For :autocorrect level, any correctable offense is a failure, regardless of severity
      return true if @options[:fail_level] == :autocorrect && offense.correctable?

      !offense.corrected? && offense.severity >= minimum_severity_to_fail
    end

    def offense_displayed?(offense)
      if @options[:display_only_fail_level_offenses]
        considered_failure?(offense)
      elsif @options[:display_only_safe_correctable]
        supports_safe_autocorrect?(offense)
      elsif @options[:display_only_correctable]
        offense.correctable?
      else
        true
      end
    end

    def offenses_to_report(offenses)
      offenses.select { |o| offense_displayed?(o) }
    end

    def supports_safe_autocorrect?(offense)
      cop_class = Cop::Registry.global.find_by_cop_name(offense.cop_name)
      default_cfg = default_config(offense.cop_name)

      offense.correctable? &&
        cop_class&.support_autocorrect? && mark_as_safe_by_config?(default_cfg)
    end

    def mark_as_safe_by_config?(config)
      config.nil? || (config.fetch('Safe', true) && config.fetch('SafeAutoCorrect', true))
    end

    def default_config(cop_name)
      RuboCop::ConfigLoader.default_configuration[cop_name]
    end

    def minimum_severity_to_fail
      @minimum_severity_to_fail ||= begin
        # Unless given explicitly as `fail_level`, `:info` severity offenses do not fail
        name = @options[:fail_level] || :refactor

        # autocorrect is a fake level - use the default
        RuboCop::Cop::Severity.new(name == :autocorrect ? :refactor : name)
      end
    end

    # rubocop:disable Metrics/MethodLength
    def get_processed_source(file)
      config = @config_store.for_file(file)
      ruby_version = config.target_ruby_version
      parser_engine = config.parser_engine

      processed_source = if @options[:stdin]
                           ProcessedSource.new(
                             @options[:stdin],
                             ruby_version,
                             file,
                             parser_engine: parser_engine,
                             prism_result: @prism_result
                           )
                         else
                           begin
                             ProcessedSource.from_file(
                               file, ruby_version, parser_engine: parser_engine
                             )
                           rescue Errno::ENOENT
                             raise RuboCop::Error, "No such file or directory: #{file}"
                           end
                         end
      processed_source.config = config
      processed_source.registry = mobilized_cop_classes(config)
      processed_source
    end
    # rubocop:enable Metrics/MethodLength

    # A Cop::Team instance is stateful and may change when inspecting.
    # The "standby" team for a given config is an initialized but
    # otherwise dormant team that can be used for config- and option-
    # level caching in ResultCache.
    def standby_team(config)
      @team_by_config ||= {}.compare_by_identity
      @team_by_config[config] ||=
        Cop::Team.mobilize(mobilized_cop_classes(config), config, @options)
    end
  end
end
