require 'brakeman/options'

module Brakeman

  # Implements handling of running Brakeman from the command line.
  class Commandline
    class << self

      # Main method to run Brakeman from the command line.
      #
      # If no options are provided, ARGV will be parsed and used instead.
      # Otherwise, the options are expected to be a Hash like the one returned
      # after ARGV is parsed.
      def start options = nil, app_path = "."

        unless options
          options, app_path = parse_options ARGV
        end

        run options, app_path
      end

      # Runs everything:
      #
      # - `set_interrupt_handler`
      # - `early_exit_options`
      # - `set_options`
      # - `check_latest`
      # - `run_report`
      def run options, default_app_path = "."
        set_interrupt_handler options
        early_exit_options options
        set_options options, default_app_path
        check_latest if options[:ensure_latest]
        run_report options
      end

      # Check for the latest version.
      #
      # If the latest version is newer, quit with a message.
      def check_latest
        if error = Brakeman.ensure_latest
          quit Brakeman::Not_Latest_Version_Exit_Code, error
        end
      end

      # Runs a comparison report based on the options provided.
      def compare_results options
        require 'json'
        vulns = Brakeman.compare options.merge(:quiet => options[:quiet])

        if options[:comparison_output_file]
          File.open options[:comparison_output_file], "w" do |f|
            f.puts JSON.pretty_generate(vulns)
          end

          Brakeman.notify "Comparison saved in '#{options[:comparison_output_file]}'"
        else
          puts JSON.pretty_generate(vulns)
        end

        if options[:exit_on_warn] && vulns[:new].count > 0
          quit Brakeman::Warnings_Found_Exit_Code
        end
      end

      # Handle options that exit without generating a report.
      def early_exit_options options
        if options[:list_checks] or options[:list_optional_checks]
          Brakeman.list_checks options
          quit
        elsif options[:create_config]
          Brakeman.dump_config options
          quit
        elsif options[:show_help]
          puts Brakeman::Options.create_option_parser({})
          quit
        elsif options[:show_version]
          require 'brakeman/version'
          puts "brakeman #{Brakeman::Version}"
          quit
        end
      end

      # Parse ARGV-style array of options.
      #
      # Exits if options are invalid.
      #
      # Returns an option hash and the app_path.
      def parse_options argv
        begin
          options, _ = Brakeman::Options.parse! argv
        rescue OptionParser::ParseError => e
          $stderr.puts e.message
          $stderr.puts "Please see `brakeman --help` for valid options"
          quit(-1)
        end

        if argv[-1]
          app_path = argv[-1]
        else
          app_path = "."
        end

        if options[:ensure_ignore_notes] and options[:previous_results_json]
          warn '[Notice] --ensure-ignore-notes may not be used at the same ' \
               'time as --compare. Deactivating --ensure-ignore-notes. ' \
               'Please see `brakeman --help` for valid options'
          options[:ensure_ignore_notes] = false
        end

        return options, app_path
      end

      # Exits with the given exit code and prints out the message, if given.
      #
      # Override this method for different behavior.
      def quit exit_code = 0, message = nil
        warn message if message
        exit exit_code
      end

      # Runs a regular report based on the options provided.
      def regular_report options
        tracker = run_brakeman options

        ensure_ignore_notes_failed = false
        if tracker.options[:ensure_ignore_notes]
          fingerprints = Brakeman::ignore_file_entries_with_empty_notes tracker.ignored_filter&.file

          unless fingerprints.empty?
            ensure_ignore_notes_failed = true
            warn '[Error] Notes required for all ignored warnings when ' \
              '--ensure-ignore-notes is set. No notes provided for these ' \
              'warnings: '
            fingerprints.each { |f| warn f }
          end
        end

        if tracker.options[:exit_on_warn] and not tracker.filtered_warnings.empty?
          quit Brakeman::Warnings_Found_Exit_Code
        end

        if tracker.options[:exit_on_error] and tracker.errors.any?
          quit Brakeman::Errors_Found_Exit_Code
        end

        if ensure_ignore_notes_failed
          quit Brakeman::Empty_Ignore_Note_Exit_Code
        end
      end

      # Actually run Brakeman.
      #
      # Returns a Tracker object.
      def run_brakeman options
        Brakeman.run options.merge(:print_report => true, :quiet => options[:quiet])
      end

      # Run either a comparison or regular report based on options provided.
      def run_report options
        begin
          if options[:previous_results_json]
            compare_results options
          else
            regular_report options
          end
        rescue Brakeman::NoApplication => e
          quit Brakeman::No_App_Found_Exit_Code, e.message
        rescue Brakeman::MissingChecksError => e
          quit Brakeman::Missing_Checks_Exit_Code, e.message
        end
      end

      # Sets interrupt handler to gracefully handle Ctrl+C
      def set_interrupt_handler options
        trap("INT") do
          warn "\nInterrupted - exiting."

          if options[:debug]
            warn caller
          end

          exit!
        end
      end

      # Modifies options, including setting the app_path
      # if none is given in the options hash.
      def set_options options, default_app_path = "."
        unless options[:app_path]
          options[:app_path] = default_app_path
        end

        if options[:quiet].nil?
          options[:quiet] = :command_line
        end

        options
      end
    end
  end
end
