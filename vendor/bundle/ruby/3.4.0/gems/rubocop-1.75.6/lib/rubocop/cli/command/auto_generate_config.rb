# frozen_string_literal: true

module RuboCop
  class CLI
    module Command
      # Generate a configuration file acting as a TODO list.
      # @api private
      class AutoGenerateConfig < Base
        self.command_name = :auto_gen_config

        AUTO_GENERATED_FILE = '.rubocop_todo.yml'
        YAML_OPTIONAL_DOC_START = /\A---(\s+#|\s*\z)/.freeze
        PLACEHOLDER = '###rubocop:inherit_here'

        PHASE_1 = 'Phase 1 of 2: run Layout/LineLength cop'
        PHASE_2 = 'Phase 2 of 2: run all cops'

        PHASE_1_OVERRIDDEN = '(skipped because the default Layout/LineLength:Max is overridden)'
        PHASE_1_DISABLED = '(skipped because Layout/LineLength is disabled)'
        PHASE_1_SKIPPED_ONLY_COPS =
          '(skipped because a list of cops is passed to the `--only` flag)'
        PHASE_1_SKIPPED_ONLY_EXCLUDE =
          '(skipped because only excludes will be generated due to `--auto-gen-only-exclude` flag)'

        def run
          add_formatter
          reset_config_and_auto_gen_file
          line_length_contents = maybe_run_line_length_cop
          run_all_cops(line_length_contents)
        end

        private

        def maybe_run_line_length_cop
          if only_exclude?
            skip_line_length_cop(PHASE_1_SKIPPED_ONLY_EXCLUDE)
          elsif !line_length_enabled?(@config_store.for_pwd)
            skip_line_length_cop(PHASE_1_DISABLED)
          elsif !same_max_line_length?(@config_store.for_pwd, ConfigLoader.default_configuration)
            skip_line_length_cop(PHASE_1_OVERRIDDEN)
          elsif options_has_only_flag?
            skip_line_length_cop(PHASE_1_SKIPPED_ONLY_COPS)
          else
            run_line_length_cop
          end
        end

        def skip_line_length_cop(reason)
          puts Rainbow("#{PHASE_1} #{reason}").yellow
          ''
        end

        def line_length_enabled?(config)
          line_length_cop(config)['Enabled']
        end

        def same_max_line_length?(config1, config2)
          max_line_length(config1) == max_line_length(config2)
        end

        def max_line_length(config)
          line_length_cop(config)['Max']
        end

        def line_length_cop(config)
          config.for_cop('Layout/LineLength')
        end

        def options_has_only_flag?
          @options[:only]
        end

        def only_exclude?
          @options[:auto_gen_only_exclude]
        end

        # Do an initial run with only Layout/LineLength so that cops that
        # depend on Layout/LineLength:Max get the correct value for that
        # parameter.
        def run_line_length_cop
          puts Rainbow(PHASE_1).yellow
          @options[:only] = ['Layout/LineLength']
          execute_runner
          @options.delete(:only)
          @config_store = ConfigStore.new
          @config_store.options_config = @options[:config] if @options[:config]
          # Save the todo configuration of the LineLength cop.
          File.read(AUTO_GENERATED_FILE).lines.drop_while { |line| line.start_with?('#') }.join
        end

        def run_all_cops(line_length_contents)
          puts Rainbow(PHASE_2).yellow
          result = execute_runner
          # This run was made with the current maximum length allowed, so append
          # the saved setting for LineLength.
          File.open(AUTO_GENERATED_FILE, 'a') { |f| f.write(line_length_contents) }
          result
        end

        def reset_config_and_auto_gen_file
          @config_store = ConfigStore.new
          @config_store.options_config = @options[:config] if @options[:config]
          File.open(AUTO_GENERATED_FILE, 'w') {} # create or truncate if exists
          add_inheritance_from_auto_generated_file(@options[:config])
        end

        def add_formatter
          @options[:formatters] << [Formatter::DisabledConfigFormatter, AUTO_GENERATED_FILE]
        end

        def execute_runner
          Environment.new(@options, @config_store, @paths).run(:execute_runner)
        end

        def add_inheritance_from_auto_generated_file(config_file)
          file_string = " #{relative_path_to_todo_from_options_config}"

          config_file ||= ConfigFinder::DOTFILE

          if File.exist?(config_file)
            files = Array(ConfigLoader.load_yaml_configuration(config_file)['inherit_from'])

            return if files.include?(relative_path_to_todo_from_options_config)

            files.unshift(relative_path_to_todo_from_options_config)
            file_string = "\n  - #{files.join("\n  - ")}" if files.size > 1
            rubocop_yml_contents = existing_configuration(config_file)
          end

          write_config_file(config_file, file_string, rubocop_yml_contents)

          puts "Added inheritance from `#{relative_path_to_todo_from_options_config}` " \
               "in `#{ConfigFinder::DOTFILE}`."
        end

        def existing_configuration(config_file)
          File.read(config_file, encoding: Encoding::UTF_8)
              .sub(/^inherit_from: *[^\n]+/, PLACEHOLDER)
              .sub(/^inherit_from: *(\n *- *[^\n]+)+/, PLACEHOLDER)
        end

        def write_config_file(file_name, file_string, rubocop_yml_contents)
          lines = /\S/.match?(rubocop_yml_contents) ? rubocop_yml_contents.split("\n", -1) : []
          unless rubocop_yml_contents&.include?(PLACEHOLDER)
            doc_start_index = lines.index { |line| YAML_OPTIONAL_DOC_START.match?(line) } || -1
            lines.insert(doc_start_index + 1, PLACEHOLDER)
          end
          File.write(file_name, lines.join("\n")
                                     .sub(/#{PLACEHOLDER}\n*/o, "inherit_from:#{file_string}\n\n")
                                     .sub(/\n\n+\Z/, "\n"))
        end

        def relative_path_to_todo_from_options_config
          return AUTO_GENERATED_FILE unless @options[:config]

          base = Pathname.new(Dir.pwd)
          config_dir = Pathname.new(@options[:config]).realpath.dirname

          # Don't have the path start with `/`
          return AUTO_GENERATED_FILE if config_dir == base

          "#{base.relative_path_from(config_dir)}/#{AUTO_GENERATED_FILE}"
        end
      end
    end
  end
end
