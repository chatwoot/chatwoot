require 'optparse'
require 'set'

#Parses command line arguments for Brakeman
module Brakeman::Options

  class << self

    #Parse argument array
    def parse args
      get_options args
    end

    #Parse arguments and remove them from the array as they are matched
    def parse! args
      get_options args, true
    end

    #Return hash of options and the parser
    def get_options args, destructive = false
      options = {}

      parser = create_option_parser options

      if destructive
        parser.parse! args
      else
        parser.parse args
      end

      if options[:previous_results_json] and options[:output_files]
        options[:comparison_output_file] = options[:output_files].shift
      end

      return options, parser
    end

    def create_option_parser options
      OptionParser.new do |opts|
        opts.banner = "Usage: brakeman [options] rails/root/path"

        opts.on "-n", "--no-threads", "Run checks and file parsing sequentially" do
          options[:parallel_checks] = false
        end

        opts.on "--[no-]progress", "Show progress reports" do |progress|
          options[:report_progress] = progress
        end

        opts.on "-p", "--path PATH", "Specify path to Rails application" do |path|
          options[:app_path] = path
        end

        opts.on "-q", "--[no-]quiet", "Suppress informational messages" do |quiet|
          options[:quiet] = quiet
        end

        opts.on( "-z", "--[no-]exit-on-warn", "Exit code is non-zero if warnings found (Default)") do |exit_on_warn|
          options[:exit_on_warn] = exit_on_warn
        end

        opts.on "--[no-]exit-on-error", "Exit code is non-zero if errors raised (Default)" do |exit_on_error|
          options[:exit_on_error] = exit_on_error
        end

        opts.on "--ensure-latest", "Fail when Brakeman is outdated" do
          options[:ensure_latest] = true
        end

        opts.on "--ensure-ignore-notes", "Fail when an ignored warnings does not include a note" do
          options[:ensure_ignore_notes] = true
        end

        opts.on "-3", "--rails3", "Force Rails 3 mode" do
          options[:rails3] = true
        end

        opts.on "-4", "--rails4", "Force Rails 4 mode" do
          options[:rails3] = true
          options[:rails4] = true
        end

        opts.on "-5", "--rails5", "Force Rails 5 mode" do
          options[:rails3] = true
          options[:rails4] = true
          options[:rails5] = true
        end

        opts.on "-6", "--rails6", "Force Rails 6 mode" do
          options[:rails3] = true
          options[:rails4] = true
          options[:rails5] = true
          options[:rails6] = true
        end

        opts.on "-7", "--rails7", "Force Rails 7 mode" do
          options[:rails3] = true
          options[:rails4] = true
          options[:rails5] = true
          options[:rails6] = true
          options[:rails7] = true
        end

        opts.separator ""
        opts.separator "Scanning options:"

        opts.on "-A", "--run-all-checks", "Run all default and optional checks" do
          options[:run_all_checks] = true
        end

        opts.on "-a", "--[no-]assume-routes", "Assume all controller methods are actions (Default)" do |assume|
          options[:assume_all_routes] = assume
        end

        opts.on "-e", "--escape-html", "Escape HTML by default" do
          options[:escape_html] = true
        end

        opts.on "--faster", "Faster, but less accurate scan" do
          options[:ignore_ifs] = true
          options[:skip_libs] = true
          options[:disable_constant_tracking] = true
        end

        opts.on "--ignore-model-output", "Consider model attributes XSS-safe" do
          options[:ignore_model_output] = true
        end

        opts.on "--ignore-protected", "Consider models with attr_protected safe" do
          options[:ignore_attr_protected] = true
        end

        opts.on "--[no-]index-libs", "Add libraries to call index (Default)" do |index|
          options[:index_libs] = index
        end

        opts.on "--interprocedural", "Process method calls to known methods" do
          options[:interprocedural] = true
        end

        opts.on "--no-branching", "Disable flow sensitivity on conditionals" do
          options[:ignore_ifs] = true
        end

        opts.on "--branch-limit LIMIT", Integer, "Limit depth of values in branches (-1 for no limit)" do |limit|
          options[:branch_limit] = limit
        end

        opts.on "--parser-timeout SECONDS", Integer, "Set parse timeout (Default: 10)" do |timeout|
          options[:parser_timeout] = timeout
        end

        opts.on "-r", "--report-direct", "Only report direct use of untrusted data" do |option|
          options[:check_arguments] = !option
        end

        opts.on "-s", "--safe-methods meth1,meth2,etc", Array, "Set methods as safe for unescaped output in views" do |methods|
          options[:safe_methods] ||= Set.new
          options[:safe_methods].merge methods.map {|e| e.to_sym }
        end

        opts.on "--sql-safe-methods meth1,meth2,etc", Array, "Do not warn of SQL if the input is wrapped in a safe method" do |methods|
          options[:sql_safe_methods] ||= Set.new
          options[:sql_safe_methods].merge methods.map {|e| e.to_sym }
        end

        opts.on "--url-safe-methods method1,method2,etc", Array, "Do not warn of XSS if the link_to href parameter is wrapped in a safe method" do |methods|
          options[:url_safe_methods] ||= Set.new
          options[:url_safe_methods].merge methods.map {|e| e.to_sym }
        end

        opts.on "--skip-files file1,path2,etc", Array, "Skip processing of these files/directories. Directories are application relative and must end in \"#{File::SEPARATOR}\"" do |files|
          options[:skip_files] ||= Set.new
          options[:skip_files].merge files
        end

        opts.on "--only-files file1,path2,etc", Array, "Process only these files/directories. Directories are application relative and must end in \"#{File::SEPARATOR}\"" do |files|
          options[:only_files] ||= Set.new
          options[:only_files].merge files
        end

        opts.on "--[no-]skip-vendor", "Skip processing vendor directory (Default)" do |skip|
          options[:skip_vendor] = skip
        end

        opts.on "--skip-libs", "Skip processing lib directory" do
          options[:skip_libs] = true
        end

        opts.on "--add-libs-path path1,path2,etc", Array, "An application relative lib directory (ex. app/mailers) to process" do |paths|
          options[:additional_libs_path] ||= Set.new
          options[:additional_libs_path].merge paths
        end

        opts.on "--add-engines-path path1,path2,etc", Array, "Include these engines in the scan" do |paths|
          options[:engine_paths] ||= Set.new
          options[:engine_paths].merge paths
        end

        opts.on "-E", "--enable Check1,Check2,etc", Array, "Enable the specified checks" do |checks|
          checks.map! do |check|
            if check.start_with? "Check"
              check
            else
              "Check" << check
            end
          end

          options[:enable_checks] ||= Set.new
          options[:enable_checks].merge checks
        end

        opts.on "-t", "--test Check1,Check2,etc", Array, "Only run the specified checks" do |checks|
          checks.each_with_index do |s, index|
            if s[0,5] != "Check"
              checks[index] = "Check" << s
            end
          end

          options[:run_checks] ||= Set.new
          options[:run_checks].merge checks
        end

        opts.on "-x", "--except Check1,Check2,etc", Array, "Skip the specified checks" do |skip|
          skip.each do |s|
            if s[0,5] != "Check"
              s = "Check" << s
            end

            options[:skip_checks] ||= Set.new
            options[:skip_checks] << s
          end
        end

        opts.on "--add-checks-path path1,path2,etc", Array, "A directory containing additional out-of-tree checks to run" do |paths|
          options[:additional_checks_path] ||= Set.new
          options[:additional_checks_path].merge paths.map {|p| File.expand_path p}
        end

        opts.separator ""
        opts.separator "Output options:"

        opts.on "-d", "--debug", "Lots of output" do
          options[:debug] = true
        end

        opts.on "-f",
          "--format TYPE",
          [:pdf, :text, :html, :csv, :tabs, :json, :markdown, :codeclimate, :cc, :plain, :table, :junit, :sarif, :sonar, :github],
          "Specify output formats. Default is text" do |type|

          type = "s" if type == :text
          options[:output_format] = ("to_" << type.to_s).to_sym
        end

        opts.on "--css-file CSSFile", "Specify CSS to use for HTML output" do |file|
          options[:html_style] = File.expand_path file
        end

        opts.on "-i IGNOREFILE", "--ignore-config IGNOREFILE", "Use configuration to ignore warnings" do |file|
          options[:ignore_file] = file
        end

        opts.on "-I", "--interactive-ignore", "Interactively ignore warnings" do
          options[:interactive_ignore] = true
        end

        opts.on "-l", "--[no-]combine-locations", "Combine warning locations (Default)" do |combine|
          options[:combine_locations] = combine
        end

        opts.on "--[no-]highlights", "Highlight user input in report" do |highlight|
          options[:highlight_user_input] = highlight
        end

        opts.on "--[no-]color", "Use ANSI colors in report (Default)" do |color|
          if color
            options[:output_color] = :force
          else
            options[:output_color] = color
          end
        end

        opts.on "-m", "--routes", "Report controller information" do
          options[:report_routes] = true
        end

        opts.on "--message-limit LENGTH", "Limit message length in HTML report" do |limit|
          options[:message_limit] = limit.to_i
        end

        opts.on "--[no-]pager", "Use pager for output to terminal (Default)" do |pager|
          options[:pager] = pager
        end

        opts.on "--table-width WIDTH", "Limit table width in text report" do |width|
          options[:table_width] = width.to_i
        end

        opts.on "-o", "--output FILE", "Specify files for output. Defaults to stdout. Multiple '-o's allowed" do |file|
          options[:output_files] ||= []
          options[:output_files].push(file)
        end

        opts.on "--[no-]separate-models", "Warn on each model without attr_accessible (Default)" do |separate|
          options[:collapse_mass_assignment] = !separate
        end

        opts.on "--[no-]summary", "Only output summary of warnings" do |summary_only|
          if summary_only
            options[:summary_only] = :summary_only
          else
            options[:summary_only] = :no_summary
          end
        end

        opts.on "--absolute-paths", "Output absolute file paths in reports" do
          options[:absolute_paths] = true
        end

        opts.on "--github-repo USER/REPO[/PATH][@REF]", "Output links to GitHub in markdown and HTML reports using specified repo" do |repo|
          options[:github_repo] = repo
        end

        opts.on "--text-fields field1,field2,etc.", Array, "Specify fields for text report format" do |format|
          valid_options = [:category, :category_id, :check, :code, :confidence, :cwe, :file, :fingerprint, :line, :link, :message, :render_path]

          options[:text_fields] = format.map(&:to_sym)

          if options[:text_fields] == [:all]
            options[:text_fields] = valid_options
          else
            invalid_options = (options[:text_fields] - valid_options)

            unless invalid_options.empty?
              raise OptionParser::ParseError, "\nInvalid format options: #{invalid_options.inspect}"
            end
          end
        end

        opts.on "-w",
          "--confidence-level LEVEL",
          ["1", "2", "3"],
          "Set minimal confidence level (1 - 3)" do |level|

          options[:min_confidence] =  3 - level.to_i
        end

        opts.on "--compare FILE", "Compare the results of a previous Brakeman scan (only JSON is supported)" do |file|
          options[:previous_results_json] = File.expand_path(file)
        end

        opts.separator ""
        opts.separator "Configuration files:"

        opts.on "-c", "--config-file FILE", "Use specified configuration file" do |file|
          options[:config_file] = File.expand_path(file)
        end

        opts.on "-C", "--create-config [FILE]", "Output configuration file based on options" do |file|
          if file
            options[:create_config] = file
          else
            options[:create_config] = true
          end
        end

        opts.on "--allow-check-paths-in-config", "Allow loading checks from configuration file (Unsafe)" do
          options[:allow_check_paths_in_config] = true
        end

        opts.separator ""

        opts.on "-k", "--checks", "List all available vulnerability checks" do
          options[:list_checks] = true
        end

        opts.on "--optional-checks", "List optional checks" do
          options[:list_optional_checks] = true
        end

        opts.on "-v", "--version", "Show Brakeman version" do
          options[:show_version] = true
        end

        opts.on "--force-scan", "Scan application even if rails is not detected" do
          options[:force_scan] = true
        end

        opts.on_tail "-h", "--help", "Display this message" do
          options[:show_help] = true
        end
      end
    end
  end
end
