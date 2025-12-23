require 'brakeman/processors/lib/basic_processor'

class Brakeman::FindAllCalls < Brakeman::BasicProcessor
  attr_reader :calls

  def initialize tracker
    super

    @in_target = false
    @processing_class = false
    @calls = []
    @cache = {}
  end

  #Process the given source. Provide either class and method being searched
  #or the template. These names are used when reporting results.
  def process_source exp, opts
    @current_class = opts[:class]
    @current_method = opts[:method]
    @current_template = opts[:template]
    @current_file = opts[:file]
    @current_call = nil
    @full_call = nil
    process exp
  end

  #For whatever reason, originally the indexing of calls
  #was performed on individual method bodies (see process_defn).
  #This method explicitly indexes all calls everywhere given any
  #source.
  def process_all_source exp, opts
    @processing_class = true
    process_source exp, opts
  ensure
    @processing_class = false
  end

  #Process body of method
  def process_defn exp
    return exp unless @current_method or @processing_class

    # 'Normal' processing assumes the method name was given
    # as an option to `process_source` but for `process_all_source`
    # we don't want to do that.
    if @current_method.nil?
      @current_method = exp.method_name
      process_all exp.body
      @current_method = nil
    else
      process_all exp.body
    end

    exp
  end

  alias process_defs process_defn

  #Process body of block
  def process_rlist exp
    process_all exp
  end

  def process_call exp
    @calls << create_call_hash(exp).freeze
    exp
  end

  def process_iter exp
    call = exp.block_call

    if call.node_type == :call
      call_hash = create_call_hash(call)

      call_hash[:block] = exp.block
      call_hash[:block_args] = exp.block_args
      call_hash.freeze

      @calls << call_hash

      process exp.block
    else
      #Probably a :render call with block
      process call
      process exp.block
    end

    exp
  end

  #Calls to render() are converted to s(:render, ...) but we would
  #like them in the call cache still for speed
  def process_render exp
    process_all exp

    add_simple_call :render, exp

    exp
  end

  #Technically, `` is call to Kernel#`
  #But we just need them in the call cache for speed
  def process_dxstr exp
    process exp.last if sexp? exp.last

    add_simple_call :`, exp

    exp
  end

  #:"string" is equivalent to "string".to_sym
  def process_dsym exp
    exp.each { |arg| process arg if sexp? arg }

    add_simple_call :literal_to_sym, exp

    exp
  end

  # Process a dynamic regex like a call
  def process_dregx exp
    exp.each { |arg| process arg if sexp? arg }

    add_simple_call :brakeman_regex_interp, exp

    exp
  end

  #Process an assignment like a call
  def process_attrasgn exp
    process_call exp
  end

  private

  def add_simple_call method_name, exp
    @calls << { :target => nil,
                :method => method_name,
                :call => exp,
                :nested => false,
                :location => make_location,
                :parent => @current_call,
                :full_call => @full_call }.freeze
  end

  #Gets the target of a call as a Symbol
  #if possible
  def get_target exp, include_calls = false
    if sexp? exp
      case exp.node_type
      when :ivar, :lvar, :const, :lit
        exp.value
      when :true, :false
        exp[0]
      when :colon2
        class_name exp
      when :self
        @current_class || @current_module || nil
      when :params, :session, :cookies
        exp.node_type
      when :call, :safe_call
        if include_calls
          if exp.target.nil?
            exp.method
          else
            t = get_target(exp.target, :include_calls)
            if t.is_a? Symbol
              :"#{t}.#{exp.method}"
            else
              exp
            end
          end
        else
          exp
        end
      else
        exp
      end
    else
      exp
    end
  end

  #Returns method chain as an array
  #For example, User.human.alive.all would return [:User, :human, :alive, :all]
  def get_chain call
    if node_type? call, :call, :attrasgn, :safe_call, :safe_attrasgn
      get_chain(call.target) + [call.method]
    elsif call.nil?
      []
    else
      [get_target(call)]
    end
  end

  def make_location
    if @current_template
      key = [@current_template, @current_file]
      cached = @cache[key]
      return cached if cached

      @cache[key] = { :type => :template,
        :template => @current_template,
        :file => @current_file }
    else
      key = [@current_class, @current_method, @current_file]
      cached = @cache[key]
      return cached if cached
      @cache[key] = { :type => :class,
        :class => @current_class,
        :method => @current_method,
        :file => @current_file }
    end

  end

  #Return info hash for a call Sexp
  def create_call_hash exp
    target = get_target exp.target
    target_symbol = get_target(target, :include_calls)

    method = exp.method

    call_hash = {
      :target => target_symbol,
      :method => method,
      :call => exp,
      :nested => @in_target,
      :chain => get_chain(exp),
      :location => make_location,
      :parent => @current_call,
      :full_call => @full_call
    }

    unless @in_target
      @full_call = call_hash
      call_hash[:full_call] = call_hash
    end

    # Process up the call chain
    if call? target or node_type? target, :dxstr # need to index `` even if target of a call
      already_in_target = @in_target
      @in_target = true
      process target
      @in_target = already_in_target
    end

    # Process call arguments
    # but add the current call as the 'parent'
    # to any calls in the arguments
    old_parent = @current_call
    @current_call = call_hash

    # Do not set @full_call when processing arguments
    old_full_call = @full_call
    @full_call = nil

    process_call_args exp

    @current_call = old_parent
    @full_call = old_full_call

    call_hash
  end
end
