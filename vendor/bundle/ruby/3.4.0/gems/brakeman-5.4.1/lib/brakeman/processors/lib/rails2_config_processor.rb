require 'brakeman/processors/lib/basic_processor'

#Processes configuration. Results are put in tracker.config.
#
#Configuration of Rails via Rails::Initializer are stored in tracker.config.rails.
#For example:
#
#  Rails::Initializer.run |config|
#    config.action_controller.session_store = :cookie_store
#  end
#
#will be stored in
#
#  tracker.config[:rails][:action_controller][:session_store]
#
#Values for tracker.config.rails will still be Sexps.
class Brakeman::Rails2ConfigProcessor < Brakeman::BasicProcessor
  #Replace block variable in
  #
  #  Rails::Initializer.run |config|
  #
  #with this value so we can keep track of it.
  RAILS_CONFIG = Sexp.new(:const, :"!BRAKEMAN_RAILS_CONFIG")

  def initialize *args
    super
  end

  #Use this method to process configuration file
  def process_config src, current_file
    @current_file = current_file
    res = Brakeman::ConfigAliasProcessor.new.process_safely(src, nil, current_file)
    process res
  end

  #Check if config is set to use Erubis
  def process_call exp
    target = exp.target
    target = process target if sexp? target

    if exp.method == :gem and exp.first_arg.value == "erubis"
      Brakeman.notify "[Notice] Using Erubis for ERB templates"
      @tracker.config.erubis = true
    end

    exp
  end

  #Look for configuration settings
  def process_attrasgn exp
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
      options = get_rails_config exp
      level = @tracker.config.rails
      options[0..-2].each do |o|
        level[o] ||= {}
        level = level[o]
      end

      level[options.last] = exp.first_arg
    end

    exp
  end

  #Check for Rails version
  def process_cdecl exp
    #Set Rails version required
    if exp.lhs == :RAILS_GEM_VERSION
      @tracker.config.set_rails_version exp.rhs.value
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

#This is necessary to replace block variable so we can track config settings
class Brakeman::ConfigAliasProcessor < Brakeman::AliasProcessor

  RAILS_INIT = Sexp.new(:colon2, Sexp.new(:const, :Rails), :Initializer)

  #Look for a call to 
  #
  #  Rails::Initializer.run do |config|
  #    ...
  #  end
  #
  #and replace config with RAILS_CONFIG
  def process_iter exp
    target = exp.block_call.target
    method = exp.block_call.method

    if sexp? target and target == RAILS_INIT and method == :run
      env[Sexp.new(:lvar, exp.block_args.value)] = Brakeman::Rails2ConfigProcessor::RAILS_CONFIG
    end

    process_default exp
  end
end
