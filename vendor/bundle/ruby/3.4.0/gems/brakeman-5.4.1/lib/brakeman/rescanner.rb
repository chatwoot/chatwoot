require 'brakeman/scanner'
require 'brakeman/util'
require 'brakeman/differ'

#Class for rescanning changed files after an initial scan
class Brakeman::Rescanner < Brakeman::Scanner
 include Brakeman::Util
  KNOWN_TEMPLATE_EXTENSIONS = Brakeman::TemplateParser::KNOWN_TEMPLATE_EXTENSIONS
  SCAN_ORDER = [:gemfile, :config, :initializer, :lib, :routes, :template,
    :model, :controller]

  #Create new Rescanner to scan changed files
  def initialize options, processor, changed_files
    super(options, processor)

    @paths = changed_files.map {|f| tracker.app_tree.file_path(f) }
    @old_results = tracker.filtered_warnings  #Old warnings from previous scan
    @changes = nil                 #True if files had to be rescanned
    @reindex = Set.new
  end

  #Runs checks.
  #Will rescan files if they have not already been scanned
  def recheck
    rescan if @changes.nil?

    tracker.run_checks if @changes

    Brakeman::RescanReport.new @old_results, tracker
  end

  #Rescans changed files
  def rescan
    tracker.template_cache.clear

    paths_by_type = {}

    SCAN_ORDER.each do |type|
      paths_by_type[type] = []
    end

    @paths.each do |path|
      type = file_type(path)
      paths_by_type[type] << path unless type == :unknown
    end

    @changes = false

    SCAN_ORDER.each do |type|
      paths_by_type[type].each do |path|
        Brakeman.debug "Rescanning #{path} as #{type}"

        if rescan_file path, type
          @changes = true
        end
      end
    end

    if @changes and not @reindex.empty?
      tracker.reindex_call_sites @reindex
    end

    self
  end

  #Rescans a single file
  def rescan_file path, type = nil
    type ||= file_type path

    unless path.exists?
      return rescan_deleted_file path, type
    end

    case type
    when :controller
      rescan_controller path
    when :template
      rescan_template path
    when :model
      rescan_model path
    when :lib
      rescan_lib path
    when :config
      process_config
    when :initializer
      rescan_initializer path
    when :routes
      rescan_routes
    when :gemfile
      if tracker.config.has_gem? :rails_xss and tracker.config.escape_html?
        tracker.config.escape_html = false
      end

      process_gems
    else
      return false #Nothing to do, file hopefully does not need to be rescanned
    end

    true
  end

  def rescan_controller path
    controller = tracker.reset_controller path
    paths = controller.nil? ? [path] : controller.files
    parse_ruby_files(paths).each do |astfile|
      process_controller astfile
    end

    #Process data flow and template rendering
    #from the controller
    tracker.controllers.each do |name, controller|
      if controller.files.include?(path)
        tracker.templates.each do |template_name, template|
          next unless template.render_path
          if template.render_path.include_controller? name
            tracker.reset_template template_name
          end
        end

        controller.src.each do |file, src|
          @processor.process_controller_alias controller.name, src, nil, file
        end
      end
    end

    @reindex << :templates << :controllers
  end

  def rescan_template path
    return unless path.relative.match KNOWN_TEMPLATE_EXTENSIONS and path.exists?

    template_name = template_path_to_name(path)

    tracker.reset_template template_name
    fp = Brakeman::FileParser.new(tracker.app_tree, tracker.options[:parser_timeout])
    template_parser = Brakeman::TemplateParser.new(tracker, fp)
    template_parser.parse_template path, path.read
    tracker.add_errors(fp.errors)
    process_template fp.file_list.first

    @processor.process_template_alias tracker.templates[template_name]

    rescan = Set.new

    #Search for processed template and process it.
    #Search for rendered versions of template and re-render (if necessary)
    tracker.templates.each do |_name, template|
      if template.file == path or template.file.nil?
        next unless template.render_path and template.name.to_sym == template_name.to_sym

        template.render_path.each do |from|
          case from[:type]
          when :template
            rescan << [:template, from[:name]]
          when :controller
            rescan << [:controller, from[:class], from[:method]]
          end
        end
      end
    end

    rescan.each do |r|
      if r[0] == :controller
        controller = tracker.controllers[r[1]]

        controller.src.each do |file, src|
          unless @paths.include? file
            @processor.process_controller_alias controller.name, src, r[2], file
          end
        end
      elsif r[0] == :template
        template = tracker.templates[r[1]]

        rescan_template template.file
      end
    end

    @reindex << :templates
  end

  def rescan_model path
    num_models = tracker.models.length
    model = tracker.reset_model path
    paths = model.nil? ? [path] : model.files
    parse_ruby_files(paths).each do |astfile|
      process_model astfile.path, astfile.ast
    end

    #Only need to rescan other things if a model is added or removed
    if num_models != tracker.models.length
      process_template_data_flows
      process_controller_data_flows
      @reindex << :templates << :controllers
    end

    @reindex << :models
  end

  def rescan_lib path
    lib = tracker.reset_lib path
    paths = lib.nil? ? [path] : lib.files
    parse_ruby_files(paths).each do |astfile|
      process_lib astfile
    end

    lib = nil

    tracker.libs.each do |_name, library|
      if library.files.include?(path)
        lib = library
        break
      end
    end

    rescan_mixin lib if lib
  end

  def rescan_routes
    # Routes affect which controller methods are treated as actions
    # which affects which templates are rendered, so routes, controllers,
    # and templates rendered from controllers must be rescanned
    tracker.reset_routes
    tracker.reset_templates :only_rendered => true
    process_routes
    process_controller_data_flows
    @reindex << :controllers << :templates
  end

  def rescan_initializer path
    tracker.reset_initializer path

    parse_ruby_files([path]).each do |astfile|
      process_initializer astfile
    end

    @reindex << :initializers
  end

  #Handle rescanning when a file is deleted
  def rescan_deleted_file path, type
    case type
    when :controller
      rescan_controller path
    when :template
      rescan_deleted_template path
    when :model
      rescan_model path
    when :lib
      rescan_deleted_lib path
    when :initializer
      rescan_deleted_initializer path
    else
      if remove_deleted_file path
        return true
      else
        Brakeman.notify "Ignoring deleted file: #{path}"
      end
    end

    true
  end

  def rescan_deleted_template path
    return unless path.relative.match KNOWN_TEMPLATE_EXTENSIONS

    template_name = template_path_to_name(path)

    #Remove template
    tracker.reset_template template_name

    #Remove any rendered versions, or partials rendered from it
    tracker.templates.delete_if do |_name, template|
      template.file == path or template.name.to_sym == template_name.to_sym
    end
  end

  def rescan_deleted_lib path
    deleted_lib = nil

    tracker.libs.delete_if do |_name, lib|
      if lib.files.include?(path)
        deleted_lib = lib
        true
      end
    end

    rescan_mixin deleted_lib if deleted_lib
  end

  def rescan_deleted_initializer path
    tracker.initializers.delete Pathname.new(path).basename.to_s
  end

  #Check controllers, templates, models and libs for data from file
  #and delete it.
  def remove_deleted_file path
    deleted = false

    [:controllers, :models, :libs].each do |collection|
      tracker.send(collection).delete_if do |_name, data|
        if data.files.include?(path)
          deleted = true
          true
        end
      end
    end

    tracker.templates.delete_if do |_name, data|
      if data.file == path
        deleted = true
        true
      end
    end

    deleted
  end

  #Guess at what kind of file the path contains
  def file_type path
    case path
    when /\/app\/controllers/
      :controller
    when /\/app\/views/
      :template
    when /\/app\/models/
      :model
    when /\/lib/
      :lib
    when /\/config\/initializers/
      :initializer
    when /config\/routes\.rb/
      :routes
    when /\/config\/.+\.(rb|yml)/
      :config
    when /\.ruby-version/
      :config
    when /Gemfile|gems\./
      :gemfile
    else
      :unknown
    end
  end

  def rescan_mixin lib
    method_names = []

    lib.each_method do |name, _meth|
      method_names << name
    end

    to_rescan = []

    #Rescan controllers that mixed in library
    tracker.controllers.each do |_name, controller|
      if controller.includes.include? lib.name
        controller.files.each do |path|
          unless @paths.include? path
            to_rescan << path
          end
        end
      end
    end

    to_rescan.each do |controller|
      tracker.reset_controller controller
      rescan_file controller
    end

    to_rescan = []

    #Check if a method from this mixin was used to render a template.
    #This is not precise, because a different controller might have the
    #same method...
    tracker.templates.each do |name, template|
      next unless template.render_path

      if template.render_path.include_any_method? method_names
        name.to_s.match(/^([^.]+)/)

        original = tracker.templates[$1.to_sym]

        if original
          to_rescan << [name, original.file]
        end
      end
    end

    to_rescan.each do |template|
      tracker.reset_template template[0]
      rescan_file template[1]
    end
  end

  def parse_ruby_files list
    paths = list.select(&:exists?)
    file_parser = Brakeman::FileParser.new(tracker.app_tree, tracker.options[:parser_timeout], tracker.options[:parallel_checks])
    file_parser.parse_files paths
    tracker.add_errors(file_parser.errors)
    file_parser.file_list
  end
end

#Class to make reporting of rescan results simpler to deal with
class Brakeman::RescanReport
  include Brakeman::Util
  attr_reader :old_results, :new_results

  def initialize old_results, tracker
    @tracker = tracker
    @old_results = old_results
    @all_warnings = nil
    @diff = nil
  end

  #Returns true if any warnings were found (new or old)
  def any_warnings?
    not all_warnings.empty?
  end

  #Returns an array of all warnings found
  def all_warnings
    @all_warnings ||= @tracker.filtered_warnings
  end

  #Returns an array of warnings which were in the old report but are not in the
  #new report after rescanning
  def fixed_warnings
    diff[:fixed]
  end

  #Returns an array of warnings which were in the new report but were not in
  #the old report
  def new_warnings
    diff[:new]
  end

  #Returns true if there are any new or fixed warnings
  def warnings_changed?
    not (diff[:new].empty? and diff[:fixed].empty?)
  end

  #Returns a hash of arrays for :new and :fixed warnings
  def diff
    @diff ||= Brakeman::Differ.new(all_warnings, @old_results).diff
  end

  #Returns an array of warnings which were in the old report and the new report
  def existing_warnings
    @old ||= all_warnings.select do |w|
      not new_warnings.include? w
    end
  end

  #Output total, fixed, and new warnings
  def to_s(verbose = false)
    Brakeman.load_brakeman_dependency 'terminal-table'

    if !verbose
      <<-OUTPUT
Total warnings: #{all_warnings.length}
Fixed warnings: #{fixed_warnings.length}
New warnings: #{new_warnings.length}
      OUTPUT
    else
      #Eventually move this to different method, or make default to_s
      out = ""

      {:fixed => fixed_warnings, :new => new_warnings, :existing => existing_warnings}.each do |warning_type, warnings|
        if warnings.length > 0
          out << "#{warning_type.to_s.titleize} warnings: #{warnings.length}\n"

          table = Terminal::Table.new(:headings => ["Confidence", "Class", "Method", "Warning Type", "Message"]) do |t|
            warnings.sort_by { |w| w.confidence}.each do |warning|
              w = warning.to_row

              w["Confidence"] = Brakeman::Report::TEXT_CONFIDENCE[w["Confidence"]]

              t << [w["Confidence"], w["Class"], w["Method"], w["Warning Type"], w["Message"]]
            end
          end
          out << truncate_table(table.to_s)
        end
      end

      out
    end
  end
end
