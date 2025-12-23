
require 'brakeman/processors/lib/basic_processor'

#Processes configuration. Results are put in tracker.config.
#
#Configuration of Rails via Rails::Initializer are stored in tracker.config.rails.
#For example:
#
#  MyApp::Application.configure do
#    config.active_record.whitelist_attributes = true
#  end
#
#will be stored in
#
#  tracker.config.rails[:active_record][:whitelist_attributes]
#
#Values for tracker.config.rails will still be Sexps.
class Brakeman::Rails3ConfigProcessor < Brakeman::BasicProcessor
  RAILS_CONFIG = Sexp.new(:call, nil, :config)

  def initialize *args
    super
    @inside_config = false
  end

  #Use this method to process configuration file
  def process_config src, current_file
    @current_file = current_file
    res = Brakeman::AliasProcessor.new(@tracker).process_safely(src, nil, @current_file)
    process res
  end

  #Look for MyApp::Application.configure do ... end
  def process_iter exp
    call = exp.block_call

    if node_type?(call.target, :colon2) and
      call.target.rhs == :Application and
      call.method == :configure

      @inside_config = true
      process exp.block if sexp? exp.block
      @inside_config = false
    end

    exp
  end

  #Look for class Application < Rails::Application
  def process_class exp
    if exp.class_name == :Application
      @inside_config = true
      process_all exp.body if sexp? exp.body
      @inside_config = false
    end

    exp
  end

  #Look for configuration settings that
  #are just a call like
  #
  #  config.load_defaults 5.2
  def process_call exp
    return exp unless @inside_config

    if exp.target == RAILS_CONFIG and exp.first_arg
      @tracker.config.rails[exp.method] = exp.first_arg
    end

    exp
  end

  #Look for configuration settings
  def process_attrasgn exp
    return exp unless @inside_config

    if exp.target == RAILS_CONFIG
      #Get rid of '=' at end
      attribute = exp.method.to_s[0..-2].to_sym
      if exp.args.length > 1
        #Multiple arguments?...not sure if this will ever happen
        @tracker.config.rails[attribute] = exp.args
      else
        @tracker.config.rails[attribute] = exp.first_arg
      end
    elsif include_rails_config? exp
      options_path = get_rails_config exp
      @tracker.config.set_rails_config(value: exp.first_arg, path: options_path, overwrite: true)
    end

    exp
  end

  #Check if an expression includes a call to set Rails config
  def include_rails_config? exp
    target = exp.target
    if call? target
      if target.target == RAILS_CONFIG
        true
      else
        include_rails_config? target
      end
    elsif target == RAILS_CONFIG
      true
    else
      false
    end
  end

  #Returns an array of symbols for each 'level' in the config
  #
  #  config.action_controller.session_store = :cookie
  #
  #becomes
  #
  #  [:action_controller, :session_store]
  def get_rails_config exp
    if node_type? exp, :attrasgn
      attribute = exp.method.to_s[0..-2].to_sym
      get_rails_config(exp.target) << attribute
    elsif call? exp
      if exp.target == RAILS_CONFIG
        [exp.method]
      else
        get_rails_config(exp.target) << exp.method
      end
    else
      raise "WHAT"
    end
  end
end
