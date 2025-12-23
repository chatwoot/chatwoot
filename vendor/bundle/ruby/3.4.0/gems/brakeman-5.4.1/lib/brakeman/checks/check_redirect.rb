require 'brakeman/checks/base_check'

#Reports any calls to +redirect_to+ which include parameters in the arguments.
#
#For example:
#
# redirect_to params.merge(:action => :elsewhere)
class Brakeman::CheckRedirect < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Looks for calls to redirect_to with user input as arguments"

  def run_check
    @model_find_calls = Set[:all, :create, :create!, :find, :find_by_sql, :first, :first!, :last, :last!, :new, :sole]

    if tracker.options[:rails3]
      @model_find_calls.merge [:from, :group, :having, :joins, :lock, :order, :reorder, :select, :where]
    end

    if version_between? "4.0.0", "9.9.9"
      @model_find_calls.merge [:find_by, :find_by!, :take]
    end

    if version_between? "7.0.0", "9.9.9"
      @model_find_calls << :find_sole_by
    end

    methods = [:redirect_to, :redirect_back, :redirect_back_or_to]

    @tracker.find_call(:target => false, :methods => methods).each do |res|
      process_result res
    end
  end

  def process_result result
    return unless original? result

    call = result[:call]
    opt = call.first_arg

    # Location is specified with `fallback_location:`
    # otherwise the arguments do not contain a location and
    # the call can be ignored
    if call.method == :redirect_back
      if hash? opt and location = hash_access(opt, :fallback_location)
        opt = location
      else
        return
      end
    end

    if not protected_by_raise?(call) and
        not only_path?(call) and
        not explicit_host?(opt) and
        not slice_call?(opt) and
        not safe_permit?(opt) and
        not disallow_other_host?(call) and
        res = include_user_input?(opt)

      if res.type == :immediate and not allow_other_host?(call)
        confidence = :high
      else
        confidence = :weak
      end

      warn :result => result,
        :warning_type => "Redirect",
        :warning_code => :open_redirect,
        :message => "Possible unprotected redirect",
        :code => call,
        :user_input => res,
        :confidence => confidence,
        :cwe_id => [601]
    end
  end

  #Custom check for user input. First looks to see if the user input
  #is being output directly. This is necessary because of tracker.options[:check_arguments]
  #which can be used to enable/disable reporting output of method calls which use
  #user input as arguments.
  def include_user_input? opt, immediate = :immediate
    Brakeman.debug "Checking if call includes user input"

    # if the first argument is an array, rails assumes you are building a
    # polymorphic route, which will never jump off-host
    return false if array? opt

    if tracker.options[:ignore_redirect_to_model]
      if model_instance?(opt) or decorated_model?(opt)
        return false
      end
    end

    if res = has_immediate_model?(opt)
      unless call? opt and opt.method.to_s =~ /_path/
        return Match.new(immediate, res)
      end
    elsif call? opt
      if request_value? opt
        return Match.new(immediate, opt)
      elsif opt.method == :url_for and include_user_input? opt.first_arg
        return Match.new(immediate, opt)
        #Ignore helpers like some_model_url?
      elsif opt.method.to_s =~ /_(url|path)\z/
        return false
      elsif opt.method == :url_from
        return false
      end
    elsif request_value? opt
      return Match.new(immediate, opt)
    elsif node_type? opt, :or
      return (include_user_input?(opt.lhs) or include_user_input?(opt.rhs))
    end

    if tracker.options[:check_arguments] and call? opt
      include_user_input? opt.first_arg, false  #I'm doubting if this is really necessary...
    else
      false
    end
  end

  #Checks +redirect_to+ arguments for +only_path => true+ which essentially
  #nullifies the danger posed by redirecting with user input
  def only_path? call
    arg = call.first_arg

    if hash? arg
      return has_only_path? arg
    elsif call? arg and arg.method == :url_for
      return check_url_for(arg)
    elsif call? arg and hash? arg.first_arg and use_unsafe_hash_method? arg
      return has_only_path? arg.first_arg
    end

    false
  end

  def use_unsafe_hash_method? arg
    return call_has_param(arg, :to_unsafe_hash) || call_has_param(arg, :to_unsafe_h)
  end

  def call_has_param arg, key
    if call? arg and call? arg.target
      target = arg.target
      method = target.method

      node_type? target.target, :params and method == key
    else
      false
    end
  end

  def has_only_path? arg
    if value = hash_access(arg, :only_path)
      return true if true?(value)
    end

    false
  end

  def explicit_host? arg
    return unless sexp? arg

    if hash? arg
      if value = hash_access(arg, :host)
        return !has_immediate_user_input?(value)
      end
    elsif call? arg
      target = arg.target

      if hash? target and value = hash_access(target, :host)
        return !has_immediate_user_input?(value)
      elsif call? arg
        return explicit_host? target
      end
    end

    false
  end

  #+url_for+ is only_path => true by default. This checks to see if it is
  #set to false for some reason.
  def check_url_for call
    arg = call.first_arg

    if hash? arg
      if value = hash_access(arg, :only_path)
        return false if false?(value)
      end
    end

    true
  end

  #Returns true if exp is (probably) a model instance
  def model_instance? exp
    if node_type? exp, :or
      model_instance? exp.lhs or model_instance? exp.rhs
    elsif call? exp
      if model_target? exp and
        (@model_find_calls.include? exp.method or exp.method.to_s.match(/^find_by_/))
        true
      else
        association?(exp.target, exp.method)
      end
    end
  end

  def model_target? exp
    return false unless call? exp
    model_name? exp.target or
    friendly_model? exp.target or
    model_target? exp.target
  end

  #Returns true if exp is (probably) a friendly model instance
  #using the FriendlyId gem
  def friendly_model? exp
    call? exp and model_name? exp.target and exp.method == :friendly
  end

  #Returns true if exp is (probably) a decorated model instance
  #using the Draper gem
  def decorated_model? exp
    if node_type? exp, :or
      decorated_model? exp.lhs or decorated_model? exp.rhs
    else
      tracker.config.has_gem? :draper and
      call? exp and
      node_type?(exp.target, :const) and
      exp.target.value.to_s.match(/Decorator$/) and
      exp.method == :decorate
    end
  end

  #Check if method is actually an association in a Model
  def association? model_name, meth
    if call? model_name
      return association? model_name.target, meth
    elsif model_name? model_name
      model = tracker.models[class_name(model_name)]
    else
      return false
    end

    return false unless model

    model.association? meth
  end

  def slice_call? exp
    return unless call? exp
    exp.method == :slice
  end

  DANGEROUS_KEYS = [:host, :subdomain, :domain, :port]

  def safe_permit? exp
    if call? exp and params? exp.target and exp.method == :permit
      exp.each_arg do |opt|
        if symbol? opt and DANGEROUS_KEYS.include? opt.value
          return false
        end
      end

      return true
    end

    false
  end

  def protected_by_raise? call
    raise_on_redirects? and
      not allow_other_host? call
  end

  def raise_on_redirects?
    @raise_on_redirects ||= true?(tracker.config.rails.dig(:action_controller, :raise_on_open_redirects))
  end

  def allow_other_host? call
    opt = call.last_arg

    hash? opt and true? hash_access(opt, :allow_other_host)
  end

  def disallow_other_host? call
    opt = call.last_arg

    hash? opt and false? hash_access(opt, :allow_other_host)
  end
end
