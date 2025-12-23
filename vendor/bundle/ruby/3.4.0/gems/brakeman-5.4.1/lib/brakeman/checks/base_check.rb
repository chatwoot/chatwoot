require 'brakeman/processors/output_processor'
require 'brakeman/processors/lib/processor_helper'
require 'brakeman/warning'
require 'brakeman/util'
require 'brakeman/messages'

#Basis of vulnerability checks.
class Brakeman::BaseCheck < Brakeman::SexpProcessor
  include Brakeman::ProcessorHelper
  include Brakeman::SafeCallHelper
  include Brakeman::Util
  include Brakeman::Messages
  attr_reader :tracker, :warnings

  # This is for legacy support.
  # Use :high, :medium, or :low instead when creating warnings.
  CONFIDENCE = Brakeman::Warning::CONFIDENCE

  Match = Struct.new(:type, :match)

  class << self
    attr_accessor :name

    def inherited(subclass)
      subclass.name = subclass.to_s.match(/^Brakeman::(.*)$/)[1]
    end
  end

  #Initialize Check with Checks.
  def initialize(tracker)
    super()
    @app_tree = tracker.app_tree
    @results = [] #only to check for duplicates
    @warnings = []
    @tracker = tracker
    @string_interp = false
    @current_set = nil
    @current_template = @current_module = @current_class = @current_method = nil
    @active_record_models = nil
    @mass_assign_disabled = nil
    @has_user_input = nil
    @in_array = false
    @safe_input_attributes = Set[:to_i, :to_f, :arel_table, :id, :uuid]
    @comparison_ops  = Set[:==, :!=, :>, :<, :>=, :<=]
  end

  #Add result to result list, which is used to check for duplicates
  def add_result result
    location = get_location result
    location, line = get_location result

    @results << [line, location, result]
  end

  #Default Sexp processing. Iterates over each value in the Sexp
  #and processes them if they are also Sexps.
  def process_default exp
    exp.each do |e|
      process e if sexp? e
    end

    exp
  end

  #Process calls and check if they include user input
  def process_call exp
    unless @comparison_ops.include? exp.method
      process exp.target if sexp? exp.target
      process_call_args exp
    end

    target = exp.target

    unless always_safe_method? exp.method
      if params? target
        @has_user_input = Match.new(:params, exp)
      elsif cookies? target
        @has_user_input = Match.new(:cookies, exp)
      elsif request_headers? target
        @has_user_input = Match.new(:request, exp)
      elsif sexp? target and model_name? target[1] #TODO: Can this be target.target?
        @has_user_input = Match.new(:model, exp)
      end
    end

    exp
  end

  def process_if exp
    #This is to ignore user input in condition
    current_user_input = @has_user_input
    process exp.condition
    @has_user_input = current_user_input

    process exp.then_clause if sexp? exp.then_clause
    process exp.else_clause if sexp? exp.else_clause

    exp
  end

  #Note that params are included in current expression
  def process_params exp
    @has_user_input = Match.new(:params, exp)
    exp
  end

  #Note that cookies are included in current expression
  def process_cookies exp
    @has_user_input = Match.new(:cookies, exp)
    exp
  end

  def process_array exp
    @in_array = true
    process_default exp
  ensure
    @in_array = false
  end

  #Does not actually process string interpolation, but notes that it occurred.
  def process_dstr exp
    unless array_interp? exp or @string_interp # don't overwrite existing value
      @string_interp = Match.new(:interp, exp)
    end

    process_default exp
  end

  private

  # Checking for
  #
  #   %W[#{a}]
  #
  # which will be parsed as
  #
  #    s(:array, s(:dstr, "", s(:evstr, s(:call, nil, :a))))
  def array_interp? exp
    @in_array and
      string_interp? exp and
      exp[1] == "".freeze and
      exp.length == 3 # only one interpolated value
  end

  def always_safe_method? meth
    @safe_input_attributes.include? meth or
      @comparison_ops.include? meth
  end

  def boolean_method? method
    method[-1] == "?"
  end

  TEMP_FILE_PATH = s(:call, s(:call, s(:const, :Tempfile), :new), :path).freeze

  def temp_file_path? exp
    exp == TEMP_FILE_PATH
  end

  #Report a warning
  def warn options
    extra_opts = { :check => self.class.to_s }

    if options[:file]
      options[:file] = @app_tree.file_path(options[:file])
    end

    @warnings << Brakeman::Warning.new(options.merge(extra_opts))
  end

  #Run _exp_ through OutputProcessor to get a nice String.
  def format_output exp
    Brakeman::OutputProcessor.new.format(exp).gsub(/\r|\n/, "")
  end

  #Checks if mass assignment is disabled globally in an initializer.
  def mass_assign_disabled?
    return @mass_assign_disabled unless @mass_assign_disabled.nil?

    @mass_assign_disabled = false

    if version_between?("3.1.0", "3.9.9") and
      tracker.config.whitelist_attributes?

      @mass_assign_disabled = true
    elsif tracker.options[:rails4] && (!tracker.config.has_gem?(:protected_attributes) || tracker.config.whitelist_attributes?)

      @mass_assign_disabled = true
    else
      #Check for ActiveRecord::Base.send(:attr_accessible, nil)
      tracker.find_call(target: :"ActiveRecord::Base", method: :attr_accessible).each do |result|
        call = result[:call]

        if call? call
          if call.first_arg == Sexp.new(:nil)
            @mass_assign_disabled = true
            break
          end
        end
      end

      unless @mass_assign_disabled
        #Check for
        #  class ActiveRecord::Base
        #    attr_accessible nil
        #  end
        tracker.check_initializers([], :attr_accessible).each do |result|
          if result.module == "ActiveRecord" and result.result_class == :Base
            arg = result.call.first_arg

            if arg.nil? or node_type? arg, :nil
              @mass_assign_disabled = true
              break
            end
          end
        end
      end
    end

    #There is a chance someone is using Rails 3.x and the `strong_parameters`
    #gem and still using hack above, so this is a separate check for
    #including ActiveModel::ForbiddenAttributesProtection in
    #ActiveRecord::Base in an initializer.
    if not @mass_assign_disabled and version_between?("3.1.0", "3.9.9") and tracker.config.has_gem? :strong_parameters
      matches = tracker.check_initializers([], :include)
      forbidden_protection = Sexp.new(:colon2, Sexp.new(:const, :ActiveModel), :ForbiddenAttributesProtection)

      matches.each do |result|
        if call? result.call and result.call.first_arg == forbidden_protection
          @mass_assign_disabled = true
        end
      end

      unless @mass_assign_disabled
        tracker.find_call(target: :"ActiveRecord::Base", method: [:send, :include]).each do |result|
          call = result[:call]
          if call? call and (call.first_arg == forbidden_protection or call.second_arg == forbidden_protection)
            @mass_assign_disabled = true
          end
        end
      end
    end

    @mass_assign_disabled
  end

  def original? result
    return false if result[:call].original_line or duplicate? result
    add_result result
    true
  end

  #This is to avoid reporting duplicates. Checks if the result has been
  #reported already from the same line number.
  def duplicate? result, location = nil
    location, line = get_location result

    @results.each do |r|
      if r[0] == line and r[1] == location
        if tracker.options[:combine_locations]
          return true
        elsif r[2] == result
          return true
        end
      end
    end

    false
  end

  def get_location result
    if result.is_a? Hash
      line = result[:call].original_line || result[:call].line
    elsif sexp? result
      line = result.original_line || result.line
    else
      raise ArgumentError
    end

    location ||= (@current_template && @current_template.name) || @current_class || @current_module || @current_set || result[:location][:class] || result[:location][:template] || result[:location][:file].to_s

    location = location[:name] if location.is_a? Hash
    location = location.name if location.is_a? Brakeman::Collection
    location = location.to_sym

    return location, line
  end

  #Checks if _exp_ includes user input in the form of cookies, parameters,
  #request environment, or model attributes.
  #
  #If found, returns a struct containing a type (:cookies, :params, :request, :model) and
  #the matching expression (Match#type and Match#match).
  #
  #Returns false otherwise.
  def include_user_input? exp
    @has_user_input = false
    process exp
    @has_user_input
  end

  #This is used to check for user input being used directly.
  #
  ##If found, returns a struct containing a type (:cookies, :params, :request) and
  #the matching expression (Match#type and Match#match).
  #
  #Returns false otherwise.
  def has_immediate_user_input? exp
    if exp.nil?
      false
    elsif call? exp and not always_safe_method? exp.method
      if params? exp
        return Match.new(:params, exp)
      elsif cookies? exp
        return Match.new(:cookies, exp)
      elsif request_headers? exp
        return Match.new(:request, exp)
      else
        has_immediate_user_input? exp.target
      end
    elsif sexp? exp
      case exp.node_type
      when :dstr
        exp.each do |e|
          if sexp? e
            match = has_immediate_user_input?(e)
            return match if match
          end
        end
        false
      when :evstr
        if sexp? exp.value
          if exp.value.node_type == :rlist
            exp.value.each_sexp do |e|
              match = has_immediate_user_input?(e)
              return match if match
            end
            false
          else
            has_immediate_user_input? exp.value
          end
        end
      when :format
        has_immediate_user_input? exp.value
      when :if
        (sexp? exp.then_clause and has_immediate_user_input? exp.then_clause) or
        (sexp? exp.else_clause and has_immediate_user_input? exp.else_clause)
      when :or
        has_immediate_user_input? exp.lhs or
        has_immediate_user_input? exp.rhs
      when :splat, :kwsplat
        exp.each_sexp do |e|
          match = has_immediate_user_input?(e)
          return match if match
        end

        false
      when :hash
        if kwsplat? exp
          exp[1].each_sexp do |e|
            match = has_immediate_user_input?(e)
            return match if match
          end

          false
        end
      else
        false
      end
    end
  end

  #Checks for a model attribute at the top level of the
  #expression.
  def has_immediate_model? exp, out = nil
    out = exp if out.nil?

    if sexp? exp and exp.node_type == :output
      exp = exp.value
    end

    if call? exp
      target = exp.target
      method = exp.method

      if always_safe_method? method
        false
      elsif call? target and not method.to_s[-1,1] == "?"
        if has_immediate_model?(target, out)
          exp
        else
          false
        end
      elsif model_name? target
        exp
      else
        false
      end
    elsif sexp? exp
      case exp.node_type
      when :dstr
        exp.each do |e|
          if sexp? e and match = has_immediate_model?(e, out)
            return match
          end
        end
        false
      when :evstr
        if sexp? exp.value
          if exp.value.node_type == :rlist
            exp.value.each_sexp do |e|
              if match = has_immediate_model?(e, out)
                return match
              end
            end
            false
          else
            has_immediate_model? exp.value, out
          end
        end
      when :format
        has_immediate_model? exp.value, out
      when :if
        ((sexp? exp.then_clause and has_immediate_model? exp.then_clause, out) or
         (sexp? exp.else_clause and has_immediate_model? exp.else_clause, out))
      when :or
        has_immediate_model? exp.lhs or
        has_immediate_model? exp.rhs
      else
        false
      end
    end
  end

  #Checks if +exp+ is a model name.
  #
  #Prior to using this method, either @tracker must be set to
  #the current tracker, or else @models should contain an array of the model
  #names, which is available via tracker.models.keys
  def model_name? exp
    @models ||= @tracker.models.keys

    if exp.is_a? Symbol
      @models.include? exp
    elsif call? exp and exp.target.nil? and exp.method == :current_user
      true
    elsif sexp? exp
      @models.include? class_name(exp)
    else
      false
    end
  end

  #Returns true if +target+ is in +exp+
  def include_target? exp, target
    return false unless call? exp

    exp.each do |e|
      return true if e == target or include_target? e, target
    end

    false
  end

  def lts_version? version
    tracker.config.has_gem? :'railslts-version' and
    version_between? version, "2.3.18.99", tracker.config.gem_version(:'railslts-version')
  end

  def version_between? low_version, high_version, current_version = nil
    tracker.config.version_between? low_version, high_version, current_version
  end

  def gemfile_or_environment gem_name = :rails
    if gem_name and info = tracker.config.get_gem(gem_name.to_sym)
      info
    elsif @app_tree.exists?("Gemfile")
      @app_tree.file_path "Gemfile"
    elsif @app_tree.exists?("gems.rb")
      @app_tree.file_path "gems.rb"
    else
      @app_tree.file_path "config/environment.rb"
    end
  end

  def self.description
    @description
  end

  def active_record_models
    return @active_record_models if @active_record_models

    @active_record_models = {}

    tracker.models.each do |name, model|
      if model.ancestor? :"ActiveRecord::Base"
        @active_record_models[name] = model
      end
    end

    @active_record_models
  end

  STRING_METHODS = Set[:<<, :+, :concat, :prepend]
  private_constant :STRING_METHODS

  def string_building? exp
    return false unless call? exp and STRING_METHODS.include? exp.method

    node_type? exp.target, :str, :dstr or
    node_type? exp.first_arg, :str, :dstr or
    string_building? exp.target or
    string_building? exp.first_arg
  end

  I18N_CLASS = s(:const, :I18n)

  def locale_call? exp
    return unless call? exp

    (exp.target == I18N_CLASS and
     exp.method == :locale) or
    locale_call? exp.target
  end
end
