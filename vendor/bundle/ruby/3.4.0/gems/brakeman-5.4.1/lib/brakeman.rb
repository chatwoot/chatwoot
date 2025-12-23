require 'set'
require 'brakeman/version'

module Brakeman

  #This exit code is used when warnings are found and the --exit-on-warn
  #option is set
  Warnings_Found_Exit_Code = 3

  #Exit code returned when no Rails application is detected
  No_App_Found_Exit_Code = 4

  #Exit code returned when brakeman was outdated
  Not_Latest_Version_Exit_Code = 5

  #Exit code returned when user requests non-existent checks
  Missing_Checks_Exit_Code = 6

  #Exit code returned when errors were found and the --exit-on-error
  #option is set
  Errors_Found_Exit_Code = 7

  #Exit code returned when an ignored warning has no note and
  #--ensure-ignore-notes is set
  Empty_Ignore_Note_Exit_Code = 8

  @debug = false
  @quiet = false
  @loaded_dependencies = []
  @vendored_paths = false

  #Run Brakeman scan. Returns Tracker object.
  #
  #Options:
  #
  #  * :app_path - path to root of Rails app (required)
  #  * :additional_checks_path - array of additional directories containing additional out-of-tree checks to run
  #  * :additional_libs_path - array of additional application relative lib directories (ex. app/mailers) to process
  #  * :assume_all_routes - assume all methods are routes (default: true)
  #  * :check_arguments - check arguments of methods (default: true)
  #  * :collapse_mass_assignment - report unprotected models in single warning (default: false)
  #  * :combine_locations - combine warning locations (default: true)
  #  * :config_file - configuration file
  #  * :escape_html - escape HTML by default (automatic)
  #  * :exit_on_error - only affects Commandline module (default: true)
  #  * :exit_on_warn - only affects Commandline module (default: true)
  #  * :github_repo - github repo to use for file links (user/repo[/path][@ref])
  #  * :highlight_user_input - highlight user input in reported warnings (default: true)
  #  * :html_style - path to CSS file
  #  * :ignore_model_output - consider models safe (default: false)
  #  * :index_libs - add libraries to call index (default: true)
  #  * :interprocedural - limited interprocedural processing of method calls (default: false)
  #  * :message_limit - limit length of messages
  #  * :min_confidence - minimum confidence (0-2, 0 is highest)
  #  * :output_files - files for output
  #  * :output_formats - formats for output (:to_s, :to_tabs, :to_csv, :to_html)
  #  * :parallel_checks - run checks in parallel (default: true)
  #  * :parser_timeout - set timeout for parsing an individual file (default: 10 seconds)
  #  * :print_report - if no output file specified, print to stdout (default: false)
  #  * :quiet - suppress most messages (default: true)
  #  * :rails3 - force Rails 3 mode (automatic)
  #  * :rails4 - force Rails 4 mode (automatic)
  #  * :rails5 - force Rails 5 mode (automatic)
  #  * :rails6 - force Rails 6 mode (automatic)
  #  * :report_routes - show found routes on controllers (default: false)
  #  * :run_checks - array of checks to run (run all if not specified)
  #  * :safe_methods - array of methods to consider safe
  #  * :sql_safe_methods - array of sql sanitization methods to consider safe
  #  * :skip_libs - do not process lib/ directory (default: false)
  #  * :skip_vendor - do not process vendor/ directory (default: true)
  #  * :skip_checks - checks not to run (run all if not specified)
  #  * :absolute_paths - show absolute path of each file (default: false)
  #  * :summary_only - only output summary section of report for plain/table (:summary_only, :no_summary, true)
  #
  #Alternatively, just supply a path as a string.
  def self.run options
    options = set_options options

    @quiet = !!options[:quiet]
    @debug = !!options[:debug]

    if @quiet
      options[:report_progress] = false
    end

    scan options
  end

  #Sets up options for run, checks given application path
  def self.set_options options
    if options.is_a? String
      options = { :app_path => options }
    end

    if options[:quiet] == :command_line
      command_line = true
      options.delete :quiet
    end

    options = default_options.merge(load_options(options)).merge(options)

    if options[:quiet].nil? and not command_line
      options[:quiet] = true
    end

    if options[:rails4]
      options[:rails3] = true
    elsif options[:rails5]
      options[:rails3] = true
      options[:rails4] = true
    elsif options[:rails6]
      options[:rails3] = true
      options[:rails4] = true
      options[:rails5] = true
    end

    options[:output_formats] = get_output_formats options
    options[:github_url] = get_github_url options

    options
  end

  #Load options from YAML file
  def self.load_options line_options
    custom_location = line_options[:config_file]
    quiet = line_options[:quiet]
    app_path = line_options[:app_path]

    #Load configuration file
    if config = config_file(custom_location, app_path)
      require 'date' # https://github.com/dtao/safe_yaml/issues/80
      self.load_brakeman_dependency 'safe_yaml/load'
      options = SafeYAML.load_file config, :deserialize_symbols => true

      if options
        options.each { |k, v| options[k] = Set.new v if v.is_a? Array }

        # After parsing the yaml config file for options, convert any string keys into symbols.
        options.keys.select {|k| k.is_a? String}.map {|k| k.to_sym }.each {|k| options[k] = options[k.to_s]; options.delete(k.to_s) }

        unless line_options[:allow_check_paths_in_config]
          if options.include? :additional_checks_path
            options.delete :additional_checks_path

            notify "[Notice] Ignoring additional check paths in config file. Use --allow-check-paths-in-config to allow" unless (options[:quiet] || quiet)
          end
        end

        # notify if options[:quiet] and quiet is nil||false
        notify "[Notice] Using configuration in #{config}" unless (options[:quiet] || quiet)
        options
      else
        notify "[Notice] Empty configuration file: #{config}" unless quiet
        {}
      end
    else
      {}
    end
  end

  CONFIG_FILES = begin
                   [
                     File.expand_path("~/.brakeman/config.yml"),
                     File.expand_path("/etc/brakeman/config.yml")
                   ]
                 rescue ArgumentError
                   # In case $HOME or $USER aren't defined for use of `~`
                   [
                     File.expand_path("/etc/brakeman/config.yml")
                   ]
                 end

  def self.config_file custom_location, app_path
    app_config = File.expand_path(File.join(app_path, "config", "brakeman.yml"))
    supported_locations = [File.expand_path(custom_location || ""), app_config] + CONFIG_FILES
    supported_locations.detect {|f| File.file?(f) }
  end

  #Default set of options
  def self.default_options
    { :assume_all_routes => true,
      :check_arguments => true,
      :collapse_mass_assignment => false,
      :combine_locations => true,
      :engine_paths => ["engines/*"],
      :exit_on_error => true,
      :exit_on_warn => true,
      :highlight_user_input => true,
      :html_style => "#{File.expand_path(File.dirname(__FILE__))}/brakeman/format/style.css",
      :ignore_model_output => false,
      :ignore_redirect_to_model => true,
      :index_libs => true,
      :message_limit => 100,
      :min_confidence => 2,
      :output_color => true,
      :pager => true,
      :parallel_checks => true,
      :parser_timeout => 10,
      :relative_path => false,
      :report_progress => true,
      :safe_methods => Set.new,
      :sql_safe_methods => Set.new,
      :skip_checks => Set.new,
      :skip_vendor => true,
    }
  end

  #Determine output formats based on options[:output_formats]
  #or options[:output_files]
  def self.get_output_formats options
    #Set output format
    if options[:output_format] && options[:output_files] && options[:output_files].size > 1
      raise ArgumentError, "Cannot specify output format if multiple output files specified"
    end
    if options[:output_format]
      get_formats_from_output_format options[:output_format]
    elsif options[:output_files]
      get_formats_from_output_files options[:output_files]
    else
      begin
        self.load_brakeman_dependency 'terminal-table', :allow_fail
        return [:to_s]
      rescue LoadError
        return [:to_json]
      end
    end
  end

  def self.get_formats_from_output_format output_format
    case output_format
    when :html, :to_html
      [:to_html]
    when :csv, :to_csv
      [:to_csv]
    when :pdf, :to_pdf
      [:to_pdf]
    when :tabs, :to_tabs
      [:to_tabs]
    when :json, :to_json
      [:to_json]
    when :markdown, :to_markdown
      [:to_markdown]
    when :cc, :to_cc, :codeclimate, :to_codeclimate
      [:to_codeclimate]
    when :plain ,:to_plain, :text, :to_text, :to_s
      [:to_text]
    when :table, :to_table
      [:to_table]
    when :junit, :to_junit
      [:to_junit]
    when :sarif, :to_sarif
      [:to_sarif]
    when :sonar, :to_sonar
      [:to_sonar]
    when :github, :to_github
      [:to_github]
    else
      [:to_text]
    end
  end
  private_class_method :get_formats_from_output_format

  def self.get_formats_from_output_files output_files
    output_files.map do |output_file|
      case output_file
      when /\.html$/i
        :to_html
      when /\.csv$/i
        :to_csv
      when /\.pdf$/i
        :to_pdf
      when /\.tabs$/i
        :to_tabs
      when /\.json$/i
        :to_json
      when /\.md$/i
        :to_markdown
      when /(\.cc|\.codeclimate)$/i
        :to_codeclimate
      when /\.plain$/i
        :to_text
      when /\.table$/i
        :to_table
      when /\.junit$/i
        :to_junit
      when /\.sarif$/i
        :to_sarif
      when /\.sonar$/i
        :to_sonar
      when /\.github$/i
        :to_github
      else
        :to_text
      end
    end
  end
  private_class_method :get_formats_from_output_files

  def self.get_github_url options
    if github_repo = options[:github_repo]
      full_repo, ref = github_repo.split '@', 2
      name, repo, path = full_repo.split '/', 3
      unless name && repo && !(name.empty? || repo.empty?)
        raise ArgumentError, "Invalid GitHub repository format"
      end
      path.chomp '/' if path
      ref ||= 'master'
      ['https://github.com', name, repo, 'blob', ref, path].compact.join '/'
    else
      nil
    end
  end
  private_class_method :get_github_url

  #Output list of checks (for `-k` option)
  def self.list_checks options
    require 'brakeman/scanner'

    add_external_checks options

    if options[:list_optional_checks]
      $stderr.puts "Optional Checks:"
      checks = Checks.optional_checks
    else
      $stderr.puts "Available Checks:"
      checks = Checks.checks
    end

    format_length = 30

    $stderr.puts "-" * format_length
    checks.each do |check|
      $stderr.printf("%-#{format_length}s%s\n", check.name, check.description)
    end
  end

  #Output configuration to YAML
  def self.dump_config options
    require 'yaml'
    if options[:create_config].is_a? String
      file = options[:create_config]
    else
      file = nil
    end

    options.delete :create_config

    options.each do |k,v|
      if v.is_a? Set
        options[k] = v.to_a
      end
    end

    if file
      File.open file, "w" do |f|
        YAML.dump options, f
      end
      notify "Output configuration to #{file}"
    else
      notify YAML.dump(options)
    end
  end

  def self.ensure_latest
    current = Brakeman::Version
    latest = Gem.latest_version_for('brakeman').to_s
    if current != latest
      "Brakeman #{current} is not the latest version #{latest}"
    end
  end

  #Run a scan. Generally called from Brakeman.run instead of directly.
  def self.scan options
    #Load scanner
    notify "Loading scanner..."

    begin
      require 'brakeman/scanner'
    rescue LoadError
      raise NoBrakemanError, "Cannot find lib/ directory."
    end

    add_external_checks options

    #Start scanning
    scanner = Scanner.new options
    tracker = scanner.tracker

    check_for_missing_checks options[:run_checks], options[:skip_checks], options[:enable_checks]

    notify "Processing application in #{tracker.app_path}"
    scanner.process

    if options[:parallel_checks]
      notify "Running checks in parallel..."
    else
      notify "Running checks..."
    end

    tracker.run_checks

    self.filter_warnings tracker, options

    if options[:output_files]
      notify "Generating report..."

      write_report_to_files tracker, options[:output_files]
    elsif options[:print_report]
      notify "Generating report..."

      write_report_to_formats tracker, options[:output_formats]
    end

    tracker
  end

  def self.write_report_to_files tracker, output_files
    require 'fileutils'
    tracker.options[:output_color] = false unless tracker.options[:output_color] == :force

    output_files.each_with_index do |output_file, idx|
      dir = File.dirname(output_file)
      unless Dir.exist? dir
        FileUtils.mkdir_p(dir)
      end

      File.open output_file, "w" do |f|
        f.write tracker.report.format(tracker.options[:output_formats][idx])
      end
      notify "Report saved in '#{output_file}'"
    end
  end
  private_class_method :write_report_to_files

  def self.write_report_to_formats tracker, output_formats
    unless $stdout.tty? or tracker.options[:output_color] == :force
      tracker.options[:output_color] = false
    end

    if not $stdout.tty? or not tracker.options[:pager] or output_formats.length > 1 # does this ever happen??
      output_formats.each do |output_format|
        puts tracker.report.format(output_format)
      end
    else
      require "brakeman/report/pager"

      Brakeman::Pager.new(tracker).page_report(tracker.report, output_formats.first)
    end
  end
  private_class_method :write_report_to_formats

  #Rescan a subset of files in a Rails application.
  #
  #A full scan must have been run already to use this method.
  #The returned Tracker object from Brakeman.run is used as a starting point
  #for the rescan.
  #
  #Options may be given as a hash with the same values as Brakeman.run.
  #Note that these options will be merged into the Tracker.
  #
  #This method returns a RescanReport object with information about the scan.
  #However, the Tracker object will also be modified as the scan is run.
  def self.rescan tracker, files, options = {}
    require 'brakeman/rescanner'

    tracker.options.merge! options

    @quiet = !!tracker.options[:quiet]
    @debug = !!tracker.options[:debug]

    Rescanner.new(tracker.options, tracker.processor, files).recheck
  end

  def self.notify message
    $stderr.puts message unless @quiet
  end

  def self.debug message
    $stderr.puts message if @debug
  end

  # Compare JSON output from a previous scan and return the diff of the two scans
  def self.compare options
    require 'json'
    require 'brakeman/differ'
    raise ArgumentError.new("Comparison file doesn't exist") unless File.exist? options[:previous_results_json]

    begin
      previous_results = JSON.parse(File.read(options[:previous_results_json]), :symbolize_names => true)[:warnings]
    rescue JSON::ParserError
      self.notify "Error parsing comparison file: #{options[:previous_results_json]}"
      exit!
    end

    tracker = run(options)

    new_results = JSON.parse(tracker.report.to_json, :symbolize_names => true)[:warnings]

    Brakeman::Differ.new(new_results, previous_results).diff
  end

  def self.load_brakeman_dependency name, allow_fail = false
    return if @loaded_dependencies.include? name

    unless @vendored_paths
      path_load = "#{File.expand_path(File.dirname(__FILE__))}/../bundle/load.rb"

      if File.exist? path_load
        require path_load
      end

      @vendored_paths = true
    end

    begin
      require name
    rescue LoadError => e
      if allow_fail
        raise e
      else
        $stderr.puts e.message
        $stderr.puts "Please install the appropriate dependency: #{name}."
        exit!(-1)
      end
    end
  end

  # Returns an array of alert fingerprints for any ignored warnings without
  # notes found in the specified ignore file (if it exists).
  def self.ignore_file_entries_with_empty_notes file
    return [] unless file

    require 'brakeman/report/ignore/config'

    config = IgnoreConfig.new(file, nil)
    config.read_from_file
    config.already_ignored_entries_with_empty_notes.map { |i| i[:fingerprint] }
  end

  def self.filter_warnings tracker, options
    require 'brakeman/report/ignore/config'

    app_tree = Brakeman::AppTree.from_options(options)

    if options[:ignore_file]
      file = options[:ignore_file]
    elsif app_tree.exists? "config/brakeman.ignore"
      file = app_tree.expand_path("config/brakeman.ignore")
    elsif not options[:interactive_ignore]
      return
    end

    notify "Filtering warnings..."

    if options[:interactive_ignore]
      require 'brakeman/report/ignore/interactive'
      config = InteractiveIgnorer.new(file, tracker.warnings).start
    else
      notify "[Notice] Using '#{file}' to filter warnings"
      config = IgnoreConfig.new(file, tracker.warnings)
      config.read_from_file
      config.filter_ignored
    end

    tracker.ignored_filter = config
  end

  def self.add_external_checks options
    options[:additional_checks_path].each do |path|
      Brakeman::Checks.initialize_checks path
    end if options[:additional_checks_path]
  end

  def self.check_for_missing_checks included_checks, excluded_checks, enabled_checks
    checks = included_checks.to_a + excluded_checks.to_a + enabled_checks.to_a

    missing = Brakeman::Checks.missing_checks(checks)

    unless missing.empty?
      raise MissingChecksError, "Could not find specified check#{missing.length > 1 ? 's' : ''}: #{missing.map {|c| "`#{c}`"}.join(', ')}"
    end
  end

  def self.debug= val
    @debug = val
  end

  def self.quiet= val
    @quiet = val
  end

  class DependencyError < RuntimeError; end
  class NoBrakemanError < RuntimeError; end
  class NoApplication < RuntimeError; end
  class MissingChecksError < RuntimeError; end
end
