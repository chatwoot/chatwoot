require 'set'
require 'pathname'

#This is a mixin containing utility methods.
module Brakeman::Util

  QUERY_PARAMETERS = Sexp.new(:call, Sexp.new(:call, nil, :request), :query_parameters)

  PATH_PARAMETERS = Sexp.new(:call, Sexp.new(:call, nil, :request), :path_parameters)

  REQUEST_REQUEST_PARAMETERS = Sexp.new(:call, Sexp.new(:call, nil, :request), :request_parameters)

  REQUEST_PARAMETERS = Sexp.new(:call, Sexp.new(:call, nil, :request), :parameters)

  REQUEST_PARAMS = Sexp.new(:call, Sexp.new(:call, nil, :request), :params)

  REQUEST_ENV = Sexp.new(:call, Sexp.new(:call, nil, :request), :env)

  PARAMETERS = Sexp.new(:call, nil, :params)

  COOKIES = Sexp.new(:call, nil, :cookies)

  REQUEST_COOKIES = s(:call, s(:call, nil, :request), :cookies)

  SESSION = Sexp.new(:call, nil, :session)

  ALL_PARAMETERS = Set[PARAMETERS, QUERY_PARAMETERS, PATH_PARAMETERS, REQUEST_REQUEST_PARAMETERS, REQUEST_PARAMETERS, REQUEST_PARAMS]

  ALL_COOKIES = Set[COOKIES, REQUEST_COOKIES]

  SAFE_LITERAL = s(:lit, :BRAKEMAN_SAFE_LITERAL)

  #Convert a string from "something_like_this" to "SomethingLikeThis"
  #
  #Taken from ActiveSupport.
  def camelize lower_case_and_underscored_word
    lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
  end

  #Convert a string from "Something::LikeThis" to "something/like_this"
  #
  #Taken from ActiveSupport.
  def underscore camel_cased_word
    camel_cased_word.to_s.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
  end

  # stupid simple, used to delegate to ActiveSupport
  def pluralize word
    if word.end_with? 's'
      word + 'es'
    else
      word + 's'
    end
  end

  #Returns a class name as a Symbol.
  #If class name cannot be determined, returns _exp_.
  def class_name exp
    case exp
    when Sexp
      case exp.node_type
      when :const
        exp.value
      when :lvar
        exp.value.to_sym
      when :colon2
        "#{class_name(exp.lhs)}::#{exp.rhs}".to_sym
      when :colon3
        "::#{exp.value}".to_sym
      when :self
        @current_class || @current_module || nil
      else
        exp
      end
    when Symbol
      exp
    when nil
      nil
    else
      exp
    end
  end

  #Takes an Sexp like
  # (:hash, (:lit, :key), (:str, "value"))
  #and yields the key and value pairs to the given block.
  #
  #For example:
  #
  # h = Sexp.new(:hash, (:lit, :name), (:str, "bob"), (:lit, :name), (:str, "jane"))
  # names = []
  # hash_iterate(h) do |key, value|
  #   if symbol? key and key[1] == :name
  #     names << value[1]
  #   end
  # end
  # names #["bob"]
  def hash_iterate hash
    hash = remove_kwsplat(hash)

    1.step(hash.length - 1, 2) do |i|
      yield hash[i], hash[i + 1]
    end
  end

  def remove_kwsplat exp
    if exp.any? { |e| node_type? e, :kwsplat }
      exp.reject { |e| node_type? e, :kwsplat }
    else
      exp
    end
  end

  #Insert value into Hash Sexp
  def hash_insert hash, key, value
    index = 1
    hash_iterate hash.dup do |k,v|
      if k == key
        hash[index + 1] = value
        return hash
      end
      index += 2
    end

    hash << key << value

    hash
  end

  #Get value from hash using key.
  #
  #If _key_ is a Symbol, it will be converted to a Sexp(:lit, key).
  def hash_access hash, key
    if key.is_a? Symbol
      key = Sexp.new(:lit, key)
    end

    if index = hash.find_index(key) and index > 0
      return hash[index + 1]
    end

    nil
  end

  def hash_values hash
    values = hash.each_sexp.each_slice(2).map do |_, value|
      value
    end

    Sexp.new(:array).concat(values).line(hash.line)
  end

  #These are never modified
  PARAMS_SEXP = Sexp.new(:params)
  SESSION_SEXP = Sexp.new(:session)
  COOKIES_SEXP = Sexp.new(:cookies)

  #Adds params, session, and cookies to environment
  #so they can be replaced by their respective Sexps.
  def set_env_defaults
    @env[PARAMETERS] = PARAMS_SEXP
    @env[SESSION] = SESSION_SEXP
    @env[COOKIES] = COOKIES_SEXP
  end

  #Check if _exp_ represents a hash: s(:hash, {...})
  #This also includes pseudo hashes params, session, and cookies.
  def hash? exp
    exp.is_a? Sexp and (exp.node_type == :hash or
                        exp.node_type == :params or
                        exp.node_type == :session or
                        exp.node_type == :cookies)
  end

  #Check if _exp_ represents an array: s(:array, [...])
  def array? exp
    exp.is_a? Sexp and exp.node_type == :array
  end

  #Check if _exp_ represents a String: s(:str, "...")
  def string? exp
    exp.is_a? Sexp and exp.node_type == :str
  end

  def string_interp? exp
    exp.is_a? Sexp and exp.node_type == :dstr
  end

  #Check if _exp_ represents a Symbol: s(:lit, :...)
  def symbol? exp
    exp.is_a? Sexp and exp.node_type == :lit and exp[1].is_a? Symbol
  end

  #Check if _exp_ represents a method call: s(:call, ...)
  def call? exp
    exp.is_a? Sexp and
      (exp.node_type == :call or exp.node_type == :safe_call)
  end

  #Check if _exp_ represents a Regexp: s(:lit, /.../)
  def regexp? exp
    exp.is_a? Sexp and exp.node_type == :lit and exp[1].is_a? Regexp
  end

  #Check if _exp_ represents an Integer: s(:lit, ...)
  def integer? exp
    exp.is_a? Sexp and exp.node_type == :lit and exp[1].is_a? Integer
  end

  #Check if _exp_ represents a number: s(:lit, ...)
  def number? exp
    exp.is_a? Sexp and exp.node_type == :lit and exp[1].is_a? Numeric
  end

  #Check if _exp_ represents a result: s(:result, ...)
  def result? exp
    exp.is_a? Sexp and exp.node_type == :result
  end

  #Check if _exp_ represents a :true, :lit, or :string node
  def true? exp
    exp.is_a? Sexp and (exp.node_type == :true or
                        exp.node_type == :lit or
                        exp.node_type == :string)
  end

  #Check if _exp_ represents a :false or :nil node
  def false? exp
    exp.is_a? Sexp and (exp.node_type == :false or
                        exp.node_type == :nil)
  end

  #Check if _exp_ represents a block of code
  def block? exp
    exp.is_a? Sexp and (exp.node_type == :block or
                        exp.node_type == :rlist)
  end

  #Check if _exp_ is a params hash
  def params? exp
    recurse_check?(exp) { |child| child.node_type == :params or ALL_PARAMETERS.include? child }
  end

  def cookies? exp
    recurse_check?(exp) { |child| child.node_type == :cookies or ALL_COOKIES.include? child }
  end

  def recurse_check? exp, &check
    if exp.is_a? Sexp
      return true if yield(exp)

      if call? exp
        if recurse_check? exp[1], &check
          return true
        elsif exp[2] == :[]
          return recurse_check? exp[1], &check
        end
      end
    end

    false
  end

  # Only return true when accessing request headers via request.env[...]
  def request_headers? exp
    return unless sexp? exp

    if exp[1] == REQUEST_ENV
      if exp.method == :[]
        if string? exp.first_arg
          # Only care about HTTP headers, which are prefixed by 'HTTP_'
          exp.first_arg.value.start_with?('HTTP_'.freeze)
        else
          true # request.env[something]
        end
      else
        false # request.env.something
      end
    else
      false
    end
  end

  #Check if exp is params, cookies, or request_headers
  def request_value? exp
    params? exp or
    cookies? exp or
    request_headers? exp
  end

  def constant? exp
    node_type? exp, :const, :colon2, :colon3
  end

  def kwsplat? exp
    exp.is_a? Sexp and
      exp.node_type == :hash and
      exp[1].is_a? Sexp and
      exp[1].node_type == :kwsplat
  end

  #Check if _exp_ is a Sexp.
  def sexp? exp
    exp.is_a? Sexp
  end

  #Check if _exp_ is a Sexp and the node type matches one of the given types.
  def node_type? exp, *types
    exp.is_a? Sexp and types.include? exp.node_type
  end

  SIMPLE_LITERALS = [:lit, :false, :str, :true]

  def simple_literal? exp
    exp.is_a? Sexp and SIMPLE_LITERALS.include? exp.node_type
  end

  LITERALS = [*SIMPLE_LITERALS, :array, :hash]

  def literal? exp
    exp.is_a? Sexp and LITERALS.include? exp.node_type
  end

  def all_literals? exp, expected_type = :array
    node_type? exp, expected_type and
      exp.length > 1 and
      exp.all? { |e| e.is_a? Symbol or node_type? e, :lit, :str }
  end

  DIR_CONST = s(:const, :Dir)

  # Dir.glob(...).whatever
  def dir_glob? exp
    exp = exp.block_call if node_type? exp, :iter
    return unless call? exp

    (exp.target == DIR_CONST and exp.method == :glob) or dir_glob? exp.target
  end

  #Returns true if the given _exp_ contains a :class node.
  #
  #Useful for checking if a module is just a module or if it is a namespace.
  def contains_class? exp
    todo = [exp]

    until todo.empty?
      current = todo.shift

      if node_type? current, :class
        return true
      elsif sexp? current
        todo = current.sexp_body.concat todo
      end
    end

    false
  end

  def make_call target, method, *args
    call = Sexp.new(:call, target, method)

    if args.empty? or args.first.empty?
      #nothing to do
    elsif node_type? args.first, :arglist
      call.concat args.first.sexp_body
    elsif args.first.node_type.is_a? Sexp #just a list of args
      call.concat args.first
    else
      call.concat args
    end

    call
  end

  def safe_literal line = nil
    s(:lit, :BRAKEMAN_SAFE_LITERAL).line(line || 0)
  end

  def safe_literal? exp
    exp == SAFE_LITERAL
  end

  def safe_literal_target? exp
    if call? exp
      safe_literal_target? exp.target
    else
      safe_literal? exp
    end
  end

  def rails_version
    @tracker.config.rails_version
  end

  #Convert path/filename to view name
  #
  # views/test/something.html.erb -> test/something
  def template_path_to_name path
    names = path.relative.split('/')
    names.last.gsub!(/(\.(html|js)\..*|\.(rhtml|haml|erb|slim))$/, '')

    if names.include? 'views'
      names[(names.index('views') + 1)..-1]
    else
      names
    end.join('/').to_sym
  end
end
