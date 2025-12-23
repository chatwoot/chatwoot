require 'set'
require 'brakeman/call_index'
require 'brakeman/checks'
require 'brakeman/report'
require 'brakeman/processors/lib/find_call'
require 'brakeman/processors/lib/find_all_calls'
require 'brakeman/tracker/config'
require 'brakeman/tracker/constants'

#The Tracker keeps track of all the processed information.
class Brakeman::Tracker
  attr_accessor :controllers, :constants, :templates, :models, :errors,
    :checks, :initializers, :config, :routes, :processor, :libs,
    :template_cache, :options, :filter_cache, :start_time, :end_time,
    :duration, :ignored_filter, :app_tree

  #Place holder when there should be a model, but it is not
  #clear what model it will be.
  UNKNOWN_MODEL = :BrakemanUnresolvedModel

  #Creates a new Tracker.
  #
  #The Processor argument is only used by other Processors
  #that might need to access it.
  def initialize(app_tree, processor = nil, options = {})
    @app_tree = app_tree
    @processor = processor
    @options = options

    @config = Brakeman::Config.new(self)
    @templates = {}
    @controllers = {}
    #Initialize models with the unknown model so
    #we can match models later without knowing precisely what
    #class they are.
    @models = {}
    @models[UNKNOWN_MODEL] = Brakeman::Model.new(UNKNOWN_MODEL, nil, @app_tree.file_path("NOT_REAL.rb"), nil, self)
    @method_cache = {}
    @routes = {}
    @initializers = {}
    @errors = []
    @libs = {}
    @constants = Brakeman::Constants.new
    @checks = nil
    @processed = nil
    @template_cache = Set.new
    @filter_cache = {}
    @call_index = nil
    @start_time = Time.now
    @end_time = nil
    @duration = nil
  end

  #Add an error to the list. If no backtrace is given,
  #the one from the exception will be used.
  def error exception, backtrace = nil
    backtrace ||= exception.backtrace
    unless backtrace.is_a? Array
      backtrace = [ backtrace ]
    end

    Brakeman.debug exception
    Brakeman.debug backtrace

    @errors << {
      :exception => exception,
      :error => exception.to_s.gsub("\n", " "),
      :backtrace => backtrace
    }
  end

  def add_errors exceptions
    exceptions.each do |e|
      error(e)
    end
  end

  #Run a set of checks on the current information. Results will be stored
  #in Tracker#checks.
  def run_checks
    @checks = Brakeman::Checks.run_checks(self)

    @end_time = Time.now
    @duration = @end_time - @start_time
    @checks
  end

  def app_path
    @app_path ||= File.expand_path @options[:app_path]
  end

  #Iterate over all methods in controllers and models.
  def each_method
    classes = [self.controllers, self.models]

    if @options[:index_libs]
      classes << self.libs
    end

    classes.each do |set|
      set.each do |set_name, collection|
        collection.each_method do |method_name, definition|
          src = definition.src
          yield src, set_name, method_name, definition.file
        end
      end
    end
  end

  #Iterates over each template, yielding the name and the template.
  #Prioritizes templates which have been rendered.
  def each_template
    if @processed.nil?
      @processed, @rest = templates.keys.sort_by{|template| template.to_s}.partition { |k| k.to_s.include? "." }
    end

    @processed.each do |k|
      yield k, templates[k]
    end

    @rest.each do |k|
      yield k, templates[k]
    end
  end


  def each_class
    classes = [self.controllers, self.models]

    if @options[:index_libs]
      classes << self.libs
    end

    classes.each do |set|
      set.each do |set_name, collection|
        collection.src.each do |file, src|
          yield src, set_name, file
        end
      end
    end
  end

  #Find a method call.
  #
  #Options:
  #  * :target => target name(s)
  #  * :method => method name(s)
  #  * :chained => search in method chains
  #
  #If :target => false or :target => nil, searches for methods without a target.
  #Targets and methods can be specified as a symbol, an array of symbols,
  #or a regular expression.
  #
  #If :chained => true, matches target at head of method chain and method at end.
  #
  #For example:
  #
  #    find_call :target => User, :method => :all, :chained => true
  #
  #could match
  #
  #    User.human.active.all(...)
  #
  def find_call options
    index_call_sites unless @call_index
    @call_index.find_calls options
  end

  #Searches the initializers for a method call
  def check_initializers target, method
    finder = Brakeman::FindCall.new target, method, self

    initializers.sort.each do |name, initializer|
      finder.process_source initializer
    end

    finder.matches
  end

  #Returns a Report with this Tracker's information
  def report
    Brakeman::Report.new(self)
  end

  def warnings
    self.checks.all_warnings
  end

  def filtered_warnings
    if self.ignored_filter
      self.warnings.reject do |w|
        self.ignored_filter.ignored? w
      end
    else
      self.warnings
    end
  end

  def unused_fingerprints
    return [] unless self.ignored_filter
    self.ignored_filter.obsolete_fingerprints
  end

  def add_constant name, value, context = nil
    @constants.add name, value, context unless @options[:disable_constant_tracking]
  end

  # This method does not return all constants at this time,
  # just ones with "simple" values.
  def constant_lookup name
    @constants.get_simple_value name unless @options[:disable_constant_tracking]
  end

  def find_class name
    [@controllers, @models, @libs].each do |collection|
      if c = collection[name]
        return c
      end
    end

    nil
  end

  def find_method method_name, class_name, method_type = :instance
    return nil unless method_name.is_a? Symbol

    klass = find_class(class_name)
    return nil unless klass

    cache_key = [klass, method_name, method_type]

    if method = @method_cache[cache_key]
      return method
    end

    if method = klass.get_method(method_name, method_type)
      return method
    else
      # Check modules included for method definition
      # TODO: only for instance methods, otherwise check extends!
      klass.includes.each do |included_name|
        if method = find_method(method_name, included_name, method_type)
          return (@method_cache[cache_key] = method)
        end
      end

      # Not in any included modules, check the parent
      @method_cache[cache_key] = find_method(method_name, klass.parent)
    end
  end

  def index_call_sites
    finder = Brakeman::FindAllCalls.new self

    self.each_method do |definition, set_name, method_name, file|
      finder.process_source definition, :class => set_name, :method => method_name, :file => file
    end

    self.each_class do |definition, set_name, file|
      finder.process_source definition, :class => set_name, :file => file
    end

    self.each_template do |_name, template|
      finder.process_source template.src, :template => template, :file => template.file
    end

    self.initializers.each do |file_name, src|
      finder.process_all_source src, :file => file_name
    end

    @call_index = Brakeman::CallIndex.new finder.calls
  end

  #Reindex call sites
  #
  #Takes a set of symbols which can include :templates, :models,
  #or :controllers
  #
  #This will limit reindexing to the given sets
  def reindex_call_sites locations
    #If reindexing templates, models, controllers,
    #just redo everything.
    if locations.length == 3
      return index_call_sites
    end

    if locations.include? :templates
      @call_index.remove_template_indexes
    end

    classes_to_reindex = Set.new
    method_sets = []

    if locations.include? :models
      classes_to_reindex.merge self.models.keys
      method_sets << self.models
    end

    if locations.include? :controllers
      classes_to_reindex.merge self.controllers.keys
      method_sets << self.controllers
    end

    if locations.include? :initializers
      self.initializers.each do |file_name, src|
        @call_index.remove_indexes_by_file file_name
      end
    end

    @call_index.remove_indexes_by_class classes_to_reindex

    finder = Brakeman::FindAllCalls.new self

    method_sets.each do |set|
      set.each do |set_name, info|
        info.each_method do |method_name, definition|
          src = definition.src
          finder.process_source src, :class => set_name, :method => method_name, :file => definition.file
        end
      end
    end

    if locations.include? :templates
      self.each_template do |_name, template|
        finder.process_source template.src, :template => template, :file => template.file
      end
    end

    if locations.include? :initializers
      self.initializers.each do |file_name, src|
        finder.process_all_source src, :file => file_name
      end
    end

    @call_index.index_calls finder.calls
  end

  #Clear information related to templates.
  #If :only_rendered => true, will delete templates rendered from
  #controllers (but not those rendered from other templates)
  def reset_templates options = { :only_rendered => false }
    if options[:only_rendered]
      @templates.delete_if do |_name, template|
        template.rendered_from_controller?
      end
    else
      @templates = {}
    end
    @processed = nil
    @rest = nil
    @template_cache.clear
  end

  #Clear information related to template
  def reset_template name
    name = name.to_sym
    @templates.delete name
    @processed = nil
    @rest = nil
    @template_cache.clear
  end

  #Clear information related to model
  def reset_model path
    model_name = nil

    @models.each do |name, model|
      if model.files.include?(path)
        model_name = name
        break
      end
    end

    @models.delete(model_name)
  end

  #Clear information related to model
  def reset_lib path
    lib_name = nil

    @libs.each do |name, lib|
      if lib.files.include?(path)
        lib_name = name
        break
      end
    end

    @libs.delete lib_name
  end

  def reset_controller path
    controller_name = nil

    #Remove from controller
    @controllers.each do |name, controller|
      if controller.files.include?(path)
        controller_name = name

        #Remove templates rendered from this controller
        @templates.each do |template_name, template|
          if template.render_path and template.render_path.include_controller? name
            reset_template template_name
            @call_index.remove_template_indexes template_name
          end
        end

        #Remove calls indexed from this controller
        @call_index.remove_indexes_by_class [name]
        break
      end
    end
    @controllers.delete controller_name
  end

  #Clear information about routes
  def reset_routes
    @routes = {}
  end

  def reset_initializer path
    @initializers.delete_if do |file, src|
      path.relative.include? file
    end

    @call_index.remove_indexes_by_file path
  end
end
