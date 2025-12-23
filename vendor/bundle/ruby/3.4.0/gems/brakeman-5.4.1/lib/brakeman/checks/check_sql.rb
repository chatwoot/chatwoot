require 'brakeman/checks/base_check'

#This check tests for find calls which do not use Rails' auto SQL escaping
#
#For example:
# Project.find(:all, :conditions => "name = '" + params[:name] + "'")
#
# Project.find(:all, :conditions => "name = '#{params[:name]}'")
#
# User.find_by_sql("SELECT * FROM projects WHERE name = '#{params[:name]}'")
class Brakeman::CheckSQL < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Check for SQL injection"

  def run_check
    # Avoid reporting `user_input` on silly values when generating warning.
    # Note that we retroactively find `user_input` inside the "dangerous" value.
    @safe_input_attributes.merge IGNORE_METHODS_IN_SQL

    @sql_targets = [:average, :calculate, :count, :count_by_sql, :delete_all, :destroy_all,
                    :find_by_sql, :maximum, :minimum, :pluck, :sum, :update_all]
    @sql_targets.concat [:from, :group, :having, :joins, :lock, :order, :reorder, :where] if tracker.options[:rails3]
    @sql_targets.concat [:find_by, :find_by!, :find_or_create_by, :find_or_create_by!, :find_or_initialize_by, :not] if tracker.options[:rails4]

    if tracker.options[:rails6]
      @sql_targets.concat [:delete_by, :destroy_by, :rewhere, :reselect]

      @sql_targets.delete :delete_all
      @sql_targets.delete :destroy_all
    end

    if version_between?("6.1.0", "9.9.9")
      @sql_targets.delete :order
      @sql_targets.delete :reorder
      @sql_targets.delete :pluck
    end

    if version_between?("2.0.0", "3.9.9") or tracker.config.rails_version.nil?
      @sql_targets << :first << :last << :all
    end

    if version_between?("2.0.0", "4.0.99") or tracker.config.rails_version.nil?
      @sql_targets << :find
    end

    @connection_calls = [:delete, :execute, :insert, :select_all, :select_one,
      :select_rows, :select_value, :select_values]

    if tracker.options[:rails3]
      @connection_calls.concat [:exec_delete, :exec_insert, :exec_query, :exec_update]
    else
      @connection_calls.concat [:add_limit!, :add_offset_limit!, :add_lock!]
    end

    @expected_targets = active_record_models.keys + [:connection, :"ActiveRecord::Base", :Arel]

    Brakeman.debug "Finding possible SQL calls on models"
    calls = tracker.find_call(:methods => @sql_targets, :nested => true)

    narrow_targets = [:exists?, :select]
    calls.concat tracker.find_call(:targets => active_record_models.keys, :methods => narrow_targets, :chained => true)

    Brakeman.debug "Finding possible SQL calls with no target"
    calls.concat tracker.find_call(:target => nil, :methods => @sql_targets)

    Brakeman.debug "Finding possible SQL calls using constantized()"
    calls.concat tracker.find_call(:methods => @sql_targets).select { |result| constantize_call? result }

    calls.concat tracker.find_call(:targets => @expected_targets, :methods => @connection_calls, :chained => true).select { |result| connect_call? result }

    calls.concat tracker.find_call(:target => :Arel, :method => :sql)

    Brakeman.debug "Finding calls to named_scope or scope"
    calls.concat find_scope_calls

    Brakeman.debug "Processing possible SQL calls"
    calls.each { |call| process_result call }
  end

  #Find calls to named_scope() or scope() in models
  #RP 3 TODO
  def find_scope_calls
    scope_calls = []

    # Used in pre-3.1.0 versions of Rails
    ar_scope_calls(:named_scope) do |model, args|
      call = make_call(nil, :named_scope, args).line(args.line)
      scope_calls << scope_call_hash(call, model, :named_scope)
    end

    # Use in 3.1.0 and later
    ar_scope_calls(:scope) do |model, args|
      second_arg = args[2]
      next unless sexp? second_arg

      if second_arg.node_type == :iter and node_type? second_arg.block, :block, :call, :safe_call
        process_scope_with_block(model, args)
      elsif call? second_arg
        call = second_arg
        scope_calls << scope_call_hash(call, model, call.method)
      else
        call = make_call(nil, :scope, args).line(args.line)
        scope_calls << scope_call_hash(call, model, :scope)
      end
    end

    scope_calls
  end

  def ar_scope_calls(symbol_name, &block)
    active_record_models.each do |name, model|
      model_args = model.options[symbol_name]
      if model_args
        model_args.each do |args|
          yield model, args
        end
      end
    end
  end

  def scope_call_hash(call, model, method)
    { :call => call, :location => { :type => :class, :class => model.name, :file => model.file }, :method => :named_scope }
  end


  def process_scope_with_block model, args
    scope_name = args[1][1]
    block = args[-1][-1]

    # Search lambda for calls to query methods
    if block.node_type == :block
      find_calls = Brakeman::FindAllCalls.new(tracker)
      find_calls.process_source(block, :class => model.name, :method => scope_name, :file => model.file)
      find_calls.calls.each { |call| process_result(call) if @sql_targets.include?(call[:method]) }
    elsif call? block
      while call? block
        process_result :target => block.target, :method => block.method, :call => block,
          :location => { :type => :class, :class => model.name, :method => scope_name, :file => model.file }

        block = block.target
      end
    end
  end

  #Process possible SQL injection sites:
  #
  # Model#find
  #
  # Model#(named_)scope
  #
  # Model#(find|count)_by_sql
  #
  # Model#all
  #
  ### Rails 3
  #
  # Model#(where|having)
  # Model#(order|group)
  #
  ### Find Options Hash
  #
  # Dangerous keys that accept SQL:
  #
  # * conditions
  # * order
  # * having
  # * joins
  # * select
  # * from
  # * lock
  #
  def process_result result
    return if duplicate?(result) or result[:call].original_line

    call = result[:call]
    method = call.method

    dangerous_value = case method
                      when :find
                        check_find_arguments call.second_arg
                      when :exists?
                        check_exists call.first_arg
                      when :delete_all, :destroy_all
                        check_find_arguments call.first_arg
                      when :named_scope, :scope
                        check_scope_arguments call
                      when :find_by_sql, :count_by_sql
                        check_by_sql_arguments call.first_arg
                      when :calculate
                        check_find_arguments call.third_arg
                      when :last, :first, :all
                        check_find_arguments call.first_arg
                      when :average, :count, :maximum, :minimum, :sum
                        if call.length > 5
                          unsafe_sql?(call.first_arg) or check_find_arguments(call.last_arg)
                        else
                          check_find_arguments call.last_arg
                        end
                      when :where, :rewhere, :having, :find_by, :find_by!, :find_or_create_by, :find_or_create_by!, :find_or_initialize_by,:not, :delete_by, :destroy_by
                        check_query_arguments call.arglist
                      when :order, :group, :reorder
                        check_order_arguments call.arglist
                      when :joins
                        check_joins_arguments call.first_arg
                      when :from
                        unsafe_sql? call.first_arg
                      when :lock
                        check_lock_arguments call.first_arg
                      when :pluck
                        unsafe_sql? call.first_arg
                      when :sql
                        unsafe_sql? call.first_arg
                      when :update_all, :select, :reselect
                        check_update_all_arguments call.args
                      when *@connection_calls
                        check_by_sql_arguments call.first_arg
                      else
                        Brakeman.debug "Unhandled SQL method: #{method}"
                      end

    if dangerous_value
      add_result result

      input = include_user_input? dangerous_value
      if input
        confidence = :high
        user_input = input
      else
        confidence = :medium
        user_input = dangerous_value
      end

      if result[:call].target and result[:chain] and not @expected_targets.include? result[:chain].first
        confidence = case confidence
                     when :high
                       :medium
                     when :medium
                       :weak
                     else
                       confidence
                     end
      end

      warn :result => result,
        :warning_type => "SQL Injection",
        :warning_code => :sql_injection,
        :message => "Possible SQL injection",
        :user_input => user_input,
        :confidence => confidence,
        :cwe_id => [89]
    end

    if check_for_limit_or_offset_vulnerability call.last_arg
      if include_user_input? call.last_arg
        confidence = :high
      else
        confidence = :weak
      end

      warn :result => result,
        :warning_type => "SQL Injection",
        :warning_code => :sql_injection_limit_offset,
        :message => msg("Upgrade to Rails >= 2.1.2 to escape ", msg_code(":limit"), " and ", msg_code("offset"), ". Possible SQL injection"),
        :confidence => confidence,
        :cwe_id => [89]
    end
  end


  #The 'find' methods accept a number of different types of parameters:
  #
  # * The first argument might be :all, :first, or :last
  # * The first argument might be an integer ID or an array of IDs
  # * The second argument might be a hash of options, some of which are
  #   dangerous and some of which are not
  # * The second argument might contain SQL fragments as values
  # * The second argument might contain properly parameterized SQL fragments in arrays
  # * The second argument might contain improperly parameterized SQL fragments in arrays
  #
  #This method should only be passed the second argument.
  def check_find_arguments arg
    return nil if not sexp? arg or node_type? arg, :lit, :string, :str, :true, :false, :nil

    unsafe_sql? arg
  end

  def check_scope_arguments call
    scope_arg = call.second_arg #first arg is name of scope

    node_type?(scope_arg, :iter) ? unsafe_sql?(scope_arg.block) : unsafe_sql?(scope_arg)
  end

  def check_query_arguments arg
    return unless sexp? arg
    first_arg = arg[1]

    if node_type? arg, :arglist
      if arg.length > 2 and string_interp? first_arg
        # Model.where("blah = ?", blah)
        return check_string_interp first_arg
      else
        arg = first_arg
      end
    end

    if request_value? arg
      unless call? arg and params? arg.target and [:permit, :slice, :to_h, :to_hash, :symbolize_keys].include? arg.method
        # Model.where(params[:where])
        arg
      end
    elsif hash? arg and not kwsplat? arg
      #This is generally going to be a hash of column names and values, which
      #would escape the values. But the keys _could_ be user input.
      check_hash_keys arg
    elsif node_type? arg, :lit, :str
      nil
    else
      #Hashes are safe...but we check above for hash, so...?
      unsafe_sql? arg, :ignore_hash
    end
  end

  #Checks each argument to order/reorder/group for possible SQL.
  #Anything used with these methods is passed in verbatim.
  def check_order_arguments args
    return unless sexp? args

    if node_type? args, :arglist
      check_update_all_arguments(args)
    else
      unsafe_sql? args
    end
  end

  #find_by_sql and count_by_sql can take either a straight SQL string
  #or an array with values to bind.
  def check_by_sql_arguments arg
    return unless sexp? arg

    #This is kind of unnecessary, because unsafe_sql? will handle an array
    #correctly, but might be better to be explicit.
    array?(arg) ? unsafe_sql?(arg[1]) : unsafe_sql?(arg)
  end

  #joins can take a string, hash of associations, or an array of both(?)
  #We only care about the possible string values.
  def check_joins_arguments arg
    return unless sexp? arg and not node_type? arg, :hash, :string, :str

    if array? arg
      arg.each do |a|
        unsafe_arg = check_joins_arguments a
        return unsafe_arg if unsafe_arg
      end

      nil
    else
      unsafe_sql? arg
    end
  end

  def check_update_all_arguments args
    args.each do |arg|
      unsafe_arg = unsafe_sql? arg
      return unsafe_arg if unsafe_arg
    end

    nil
  end

  #Model#lock essentially only cares about strings. But those strings can be
  #any SQL fragment. This does not apply to all databases. (For those who do not
  #support it, the lock method does nothing).
  def check_lock_arguments arg
    return unless sexp? arg and not node_type? arg, :hash, :array, :string, :str

    unsafe_sql?(arg, :ignore_hash)
  end


  #Check hash keys for user input.
  #(Seems unlikely, but if a user can control the column names queried, that
  #could be bad)
  def check_hash_keys exp
    hash_iterate(exp) do |key, _value|
      unless symbol?(key)
        unsafe_key = unsafe_sql? key
        return unsafe_key if unsafe_key
      end
    end

    false
  end

  #Check an interpolated string for dangerous values.
  #
  #This method assumes values interpolated into strings are unsafe by default,
  #unless safe_value? explicitly returns true.
  def check_string_interp arg
    arg.each do |exp|
      if dangerous = unsafe_string_interp?(exp)
        return dangerous
      end
    end

    nil
  end

  TO_STRING_METHODS = [:chomp, :chop, :lstrip, :rstrip, :scrub, :squish, :strip,
                       :strip_heredoc, :to_s, :tr]

  #Returns value if interpolated value is not something safe
  def unsafe_string_interp? exp
    if node_type? exp, :evstr
      value = exp.value
    else
      value = exp
    end

    if not sexp? value
      nil
    elsif call? value and TO_STRING_METHODS.include? value.method
      unsafe_string_interp? value.target
    elsif call? value and safe_literal_target? value
      nil
    else
      case value.node_type
      when :or
        unsafe_string_interp?(value.lhs) || unsafe_string_interp?(value.rhs)
      when :dstr
        if dangerous = check_string_interp(value)
          return dangerous
        end
      else
        if safe_value? value
          nil
        elsif string_building? value
          check_for_string_building value
        else
          value
        end
      end
    end
  end

  #Checks the given expression for unsafe SQL values. If an unsafe value is
  #found, returns that value (may be the given _exp_ or a subexpression).
  #
  #Otherwise, returns false/nil.
  def unsafe_sql? exp, ignore_hash = false
    return unless sexp?(exp)

    dangerous_value = find_dangerous_value exp, ignore_hash
    safe_value?(dangerous_value) ? false : dangerous_value
  end

  #Check _exp_ for dangerous values. Used by unsafe_sql?
  def find_dangerous_value exp, ignore_hash
    case exp.node_type
    when :lit, :str, :const, :colon2, :true, :false, :nil
      nil
    when :array
      #Assume this is an array like
      #
      #  ["blah = ? AND thing = ?", ...]
      #
      #and check first value
      unsafe_sql? exp[1]
    when :dstr
      check_string_interp exp
    when :hash
      if kwsplat? exp and has_immediate_user_input? exp
        exp
      elsif not ignore_hash
        check_hash_values exp
      else
        nil
      end
    when :if
      unsafe_sql? exp.then_clause or unsafe_sql? exp.else_clause
    when :call
      unless IGNORE_METHODS_IN_SQL.include? exp.method
        if has_immediate_user_input? exp
          exp
        elsif TO_STRING_METHODS.include? exp.method
          find_dangerous_value exp.target, ignore_hash
        else
          check_call exp
        end
      end
    when :or
      if unsafe = (unsafe_sql?(exp.lhs) || unsafe_sql?(exp.rhs))
        unsafe
      else
        nil
      end
    when :block, :rlist
      unsafe_sql? exp.last
    else
      if has_immediate_user_input? exp
        exp
      else
        nil
      end
    end
  end

  #Checks hash values associated with these keys:
  #
  # * conditions
  # * order
  # * having
  # * joins
  # * select
  # * from
  # * lock
  def check_hash_values exp
    hash_iterate(exp) do |key, value|
      if symbol? key
        unsafe = case key.value
                 when :conditions, :having, :select
                   check_query_arguments value
                 when :order, :group
                   check_order_arguments value
                 when :joins
                   check_joins_arguments value
                 when :lock
                   check_lock_arguments value
                 when :from
                   unsafe_sql? value
                 else
                   nil
                 end

        return unsafe if unsafe
      end
    end

    false
  end

  def check_for_string_building exp
    return unless call? exp

    target = exp.target
    method = exp.method
    arg = exp.first_arg

    if STRING_METHODS.include? method
      check_str_target_or_arg(target, arg) or
      check_interp_target_or_arg(target, arg) or
      check_for_string_building(target) or
      check_for_string_building(arg)
    else
      nil
    end
  end

  def check_str_target_or_arg target, arg
    if string? target
      check_string_arg arg
    elsif string? arg
      check_string_arg target
    end
  end

  def check_interp_target_or_arg target, arg
    if string_interp? target or string_interp? arg
      check_string_arg target and
      check_string_arg arg
    end
  end

  def check_string_arg exp
    if safe_value? exp
      nil
    elsif string_building? exp
      check_for_string_building exp
    elsif string_interp? exp
      check_string_interp exp
    elsif call? exp and exp.method == :to_s
      check_string_arg exp.target
    else
      exp
    end
  end

  IGNORE_METHODS_IN_SQL = Set[:id, :merge_conditions, :table_name, :quoted_table_name,
    :quoted_primary_key, :to_i, :to_f, :sanitize_sql, :sanitize_sql_array,
    :sanitize_sql_for_assignment, :sanitize_sql_for_conditions, :sanitize_sql_hash,
    :sanitize_sql_hash_for_assignment, :sanitize_sql_hash_for_conditions,
    :to_sql, :sanitize, :primary_key, :table_name_prefix, :table_name_suffix,
    :where_values_hash, :foreign_key, :uuid
  ]

  def ignore_methods_in_sql
    @ignore_methods_in_sql ||= IGNORE_METHODS_IN_SQL + (tracker.options[:sql_safe_methods] || [])
  end

  def safe_value? exp
    return true unless sexp? exp

    case exp.node_type
    when :str, :lit, :const, :colon2, :nil, :true, :false
      true
    when :call
      if exp.method == :to_s or exp.method == :to_sym
        safe_value? exp.target
      else
        ignore_call? exp
      end
    when :if
      safe_value? exp.then_clause and safe_value? exp.else_clause
    when :block, :rlist
      safe_value? exp.last
    when :or
      safe_value? exp.lhs and safe_value? exp.rhs
    when :dstr
      not unsafe_string_interp? exp
    else
      false
    end
  end

  def ignore_call? exp
    return unless call? exp

    ignore_methods_in_sql.include? exp.method or
      quote_call? exp or
      arel? exp or
      exp.method.to_s.end_with? "_id" or
      number_target? exp or
      date_target? exp or
      locale_call? exp
  end

  QUOTE_METHODS = [:quote, :quote_column_name, :quoted_date, :quote_string, :quote_table_name]

  def quote_call? exp
    if call? exp.target
      exp.target.method == :connection and QUOTE_METHODS.include? exp.method
    elsif exp.target.nil?
      exp.method == :quote_value
    end
  end

  AREL_METHODS = [:all, :and, :arel_table, :as, :eq, :eq_any, :exists, :group,
                  :gt, :gteq, :having, :in, :join_sources, :limit, :lt, :lteq, :not,
                  :not_eq, :on, :or, :order, :project, :skip, :take, :where, :with]

  def arel? exp
    call? exp and (AREL_METHODS.include? exp.method or arel? exp.target)
  end

  #Check call for string building
  def check_call exp
    return unless call? exp
    unsafe = check_for_string_building exp

    if unsafe
      unsafe
    elsif call? exp.target
      check_call exp.target
    else
      nil
    end
  end

  def check_exists arg
    if call? arg and arg.method == :to_s
      false
    else
      check_find_arguments arg
    end
  end

  #Prior to Rails 2.1.1, the :offset and :limit parameters were not
  #escaping input properly.
  #
  #http://www.rorsecurity.info/2008/09/08/sql-injection-issue-in-limit-and-offset-parameter/
  def check_for_limit_or_offset_vulnerability options
    return false if rails_version.nil? or rails_version >= "2.1.1" or not hash?(options)

    return true if hash_access(options, :limit) or hash_access(options, :offset)

    false
  end

  #Look for something like this:
  #
  # params[:x].constantize.find('something')
  #
  # s(:call,
  #   s(:call,
  #     s(:call,
  #       s(:call, nil, :params, s(:arglist)),
  #       :[],
  #       s(:arglist, s(:lit, :x))),
  #     :constantize,
  #     s(:arglist)),
  #   :find,
  #   s(:arglist, s(:str, "something")))
  def constantize_call? result
    call = result[:call]
    call? call.target and call.target.method == :constantize
  end

  SELF_CLASS = s(:call, s(:self), :class)

  def connect_call? result
    call = result[:call]
    target = call.target

    if call? target and target.method == :connection
      target = target.target
      klass = class_name(target)

      target.nil? or
      target == SELF_CLASS or
      node_type? target, :self or
      klass == :"ActiveRecord::Base" or
      active_record_models.include? klass
    end
  end

  def number_target? exp
    return unless call? exp

    if number? exp.target
      true
    elsif call? exp.target
      number_target? exp.target
    else
      false
    end
  end

  DATE_CLASS = s(:const, :Date)

  def date_target? exp
    return unless call? exp

    if exp.target == DATE_CLASS
      true
    elsif call? exp.target
      date_target? exp.target
    else
     false
    end
  end
end
