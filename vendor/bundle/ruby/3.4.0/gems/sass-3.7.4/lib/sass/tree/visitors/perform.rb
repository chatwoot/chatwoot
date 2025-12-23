# A visitor for converting a dynamic Sass tree into a static Sass tree.
class Sass::Tree::Visitors::Perform < Sass::Tree::Visitors::Base
  @@function_name_deprecation = Sass::Deprecation.new

  class << self
    # @param root [Tree::Node] The root node of the tree to visit.
    # @param environment [Sass::Environment] The lexical environment.
    # @return [Tree::Node] The resulting tree of static nodes.
    def visit(root, environment = nil)
      new(environment).send(:visit, root)
    end

    # @api private
    def perform_arguments(callable, args, splat, environment)
      desc = "#{callable.type.capitalize} #{callable.name}"
      downcase_desc = "#{callable.type} #{callable.name}"

      # All keywords are contained in splat.keywords for consistency,
      # even if there were no splats passed in.
      old_keywords_accessed = splat.keywords_accessed
      keywords = splat.keywords
      splat.keywords_accessed = old_keywords_accessed

      begin
        unless keywords.empty?
          unknown_args = Sass::Util.array_minus(keywords.keys,
            callable.args.map {|var| var.first.underscored_name})
          if callable.splat && unknown_args.include?(callable.splat.underscored_name)
            raise Sass::SyntaxError.new("Argument $#{callable.splat.name} of #{downcase_desc} " +
                                        "cannot be used as a named argument.")
          elsif unknown_args.any?
            description = unknown_args.length > 1 ? 'the following arguments:' : 'an argument named'
            raise Sass::SyntaxError.new("#{desc} doesn't have #{description} " +
                                        "#{unknown_args.map {|name| "$#{name}"}.join ', '}.")
          end
        end
      rescue Sass::SyntaxError => keyword_exception
      end

      # If there's no splat, raise the keyword exception immediately. The actual
      # raising happens in the ensure clause at the end of this function.
      return if keyword_exception && !callable.splat

      splat_sep = :comma
      if splat
        args += splat.to_a
        splat_sep = splat.separator
      end

      if args.size > callable.args.size && !callable.splat
        extra_args_because_of_splat = splat && args.size - splat.to_a.size <= callable.args.size

        takes = callable.args.size
        passed = args.size
        message = "#{desc} takes #{takes} argument#{'s' unless takes == 1} " +
          "but #{passed} #{passed == 1 ? 'was' : 'were'} passed."
        raise Sass::SyntaxError.new(message) unless extra_args_because_of_splat
        # TODO: when the deprecation period is over, make this an error.
        Sass::Util.sass_warn("WARNING: #{message}\n" +
          environment.stack.to_s.gsub(/^/m, " " * 8) + "\n" +
          "This will be an error in future versions of Sass.")
      end

      env = Sass::Environment.new(callable.environment)
      callable.args.zip(args[0...callable.args.length]) do |(var, default), value|
        if value && keywords.has_key?(var.name)
          raise Sass::SyntaxError.new("#{desc} was passed argument $#{var.name} " +
                                      "both by position and by name.")
        end

        value ||= keywords.delete(var.name)
        value ||= default && default.perform(env)
        raise Sass::SyntaxError.new("#{desc} is missing argument #{var.inspect}.") unless value
        env.set_local_var(var.name, value)
      end

      if callable.splat
        rest = args[callable.args.length..-1] || []
        arg_list = Sass::Script::Value::ArgList.new(rest, keywords, splat_sep)
        arg_list.options = env.options
        env.set_local_var(callable.splat.name, arg_list)
      end

      yield env
    rescue StandardError => e
    ensure
      # If there's a keyword exception, we don't want to throw it immediately,
      # because the invalid keywords may be part of a glob argument that should be
      # passed on to another function. So we only raise it if we reach the end of
      # this function *and* the keywords attached to the argument list glob object
      # haven't been accessed.
      #
      # The keyword exception takes precedence over any Sass errors, but not over
      # non-Sass exceptions.
      if keyword_exception &&
          !(arg_list && arg_list.keywords_accessed) &&
          (e.nil? || e.is_a?(Sass::SyntaxError))
        raise keyword_exception
      elsif e
        raise e
      end
    end

    # @api private
    # @return [Sass::Script::Value::ArgList]
    def perform_splat(splat, performed_keywords, kwarg_splat, environment)
      args, kwargs, separator = [], nil, :comma

      if splat
        splat = splat.perform(environment)
        separator = splat.separator || separator
        if splat.is_a?(Sass::Script::Value::ArgList)
          args = splat.to_a
          kwargs = splat.keywords
        elsif splat.is_a?(Sass::Script::Value::Map)
          kwargs = arg_hash(splat)
        else
          args = splat.to_a
        end
      end
      kwargs ||= Sass::Util::NormalizedMap.new
      kwargs.update(performed_keywords)

      if kwarg_splat
        kwarg_splat = kwarg_splat.perform(environment)
        unless kwarg_splat.is_a?(Sass::Script::Value::Map)
          raise Sass::SyntaxError.new("Variable keyword arguments must be a map " +
                                      "(was #{kwarg_splat.inspect}).")
        end
        kwargs.update(arg_hash(kwarg_splat))
      end

      Sass::Script::Value::ArgList.new(args, kwargs, separator)
    end

    private

    def arg_hash(map)
      Sass::Util.map_keys(map.to_h) do |key|
        next key.value if key.is_a?(Sass::Script::Value::String)
        raise Sass::SyntaxError.new("Variable keyword argument map must have string keys.\n" +
          "#{key.inspect} is not a string in #{map.inspect}.")
      end
    end
  end

  protected

  def initialize(env)
    @environment = env
    @in_keyframes = false
    @at_root_without_rule = false
  end

  # If an exception is raised, this adds proper metadata to the backtrace.
  def visit(node)
    return super(node.dup) unless @environment
    @environment.stack.with_base(node.filename, node.line) {super(node.dup)}
  rescue Sass::SyntaxError => e
    e.modify_backtrace(:filename => node.filename, :line => node.line)
    raise e
  end

  # Keeps track of the current environment.
  def visit_children(parent)
    with_environment Sass::Environment.new(@environment, parent.options) do
      parent.children = super.flatten
      parent
    end
  end

  # Runs a block of code with the current environment replaced with the given one.
  #
  # @param env [Sass::Environment] The new environment for the duration of the block.
  # @yield A block in which the environment is set to `env`.
  # @return [Object] The return value of the block.
  def with_environment(env)
    old_env, @environment = @environment, env
    yield
  ensure
    @environment = old_env
  end

  # Sets the options on the environment if this is the top-level root.
  def visit_root(node)
    yield
  rescue Sass::SyntaxError => e
    e.sass_template ||= node.template
    raise e
  end

  # Removes this node from the tree if it's a silent comment.
  def visit_comment(node)
    return [] if node.invisible?
    node.resolved_value = run_interp_no_strip(node.value)
    node.resolved_value.gsub!(/\\([\\#])/, '\1')
    node
  end

  # Prints the expression to STDERR.
  def visit_debug(node)
    res = node.expr.perform(@environment)
    if res.is_a?(Sass::Script::Value::String)
      res = res.value
    else
      res = res.to_sass
    end
    if node.filename
      Sass::Util.sass_warn "#{node.filename}:#{node.line} DEBUG: #{res}"
    else
      Sass::Util.sass_warn "Line #{node.line} DEBUG: #{res}"
    end
    []
  end

  # Throws the expression as an error.
  def visit_error(node)
    res = node.expr.perform(@environment)
    if res.is_a?(Sass::Script::Value::String)
      res = res.value
    else
      res = res.to_sass
    end
    raise Sass::SyntaxError.new(res)
  end

  # Runs the child nodes once for each value in the list.
  def visit_each(node)
    list = node.list.perform(@environment)

    with_environment Sass::SemiGlobalEnvironment.new(@environment) do
      list.to_a.map do |value|
        if node.vars.length == 1
          @environment.set_local_var(node.vars.first, value)
        else
          node.vars.zip(value.to_a) do |(var, sub_value)|
            @environment.set_local_var(var, sub_value || Sass::Script::Value::Null.new)
          end
        end
        node.children.map {|c| visit(c)}
      end.flatten
    end
  end

  # Runs SassScript interpolation in the selector,
  # and then parses the result into a {Sass::Selector::CommaSequence}.
  def visit_extend(node)
    parser = Sass::SCSS::StaticParser.new(run_interp(node.selector),
      node.filename, node.options[:importer], node.line)
    node.resolved_selector = parser.parse_selector
    node
  end

  # Runs the child nodes once for each time through the loop, varying the variable each time.
  def visit_for(node)
    from = node.from.perform(@environment)
    to = node.to.perform(@environment)
    from.assert_int!
    to.assert_int!

    to = to.coerce(from.numerator_units, from.denominator_units)
    direction = from.to_i > to.to_i ? -1 : 1
    range = Range.new(direction * from.to_i, direction * to.to_i, node.exclusive)

    with_environment Sass::SemiGlobalEnvironment.new(@environment) do
      range.map do |i|
        @environment.set_local_var(node.var,
          Sass::Script::Value::Number.new(direction * i,
            from.numerator_units, from.denominator_units))
        node.children.map {|c| visit(c)}
      end.flatten
    end
  end

  # Loads the function into the environment.
  def visit_function(node)
    env = Sass::Environment.new(@environment, node.options)

    if node.normalized_name == 'calc' || node.normalized_name == 'element' ||
        node.name == 'expression' || node.name == 'url'
      @@function_name_deprecation.warn(node.filename, node.line, <<WARNING)
Naming a function "#{node.name}" is disallowed and will be an error in future versions of Sass.
This name conflicts with an existing CSS function with special parse rules.
WARNING
    end

    @environment.set_local_function(node.name,
      Sass::Callable.new(node.name, node.args, node.splat, env,
                         node.children, false, "function", :stylesheet))
    []
  end

  # Runs the child nodes if the conditional expression is true;
  # otherwise, tries the else nodes.
  def visit_if(node)
    if node.expr.nil? || node.expr.perform(@environment).to_bool
      with_environment Sass::SemiGlobalEnvironment.new(@environment) do
        node.children.map {|c| visit(c)}
      end.flatten
    elsif node.else
      visit(node.else)
    else
      []
    end
  end

  # Returns a static DirectiveNode if this is importing a CSS file,
  # or parses and includes the imported Sass file.
  def visit_import(node)
    if (path = node.css_import?)
      resolved_node = Sass::Tree::CssImportNode.resolved("url(#{path})")
      resolved_node.options = node.options
      resolved_node.source_range = node.source_range
      return resolved_node
    end
    file = node.imported_file
    if @environment.stack.frames.any? {|f| f.is_import? && f.filename == file.options[:filename]}
      handle_import_loop!(node)
    end

    begin
      @environment.stack.with_import(node.filename, node.line) do
        root = file.to_tree
        Sass::Tree::Visitors::CheckNesting.visit(root)
        node.children = root.children.map {|c| visit(c)}.flatten
        node
      end
    rescue Sass::SyntaxError => e
      e.modify_backtrace(:filename => node.imported_file.options[:filename])
      e.add_backtrace(:filename => node.filename, :line => node.line)
      raise e
    end
  end

  # Loads a mixin into the environment.
  def visit_mixindef(node)
    env = Sass::Environment.new(@environment, node.options)
    @environment.set_local_mixin(node.name,
      Sass::Callable.new(node.name, node.args, node.splat, env,
                         node.children, node.has_content, "mixin", :stylesheet))
    []
  end

  # Runs a mixin.
  def visit_mixin(node)
    @environment.stack.with_mixin(node.filename, node.line, node.name) do
      mixin = @environment.mixin(node.name)
      raise Sass::SyntaxError.new("Undefined mixin '#{node.name}'.") unless mixin

      if node.has_children && !mixin.has_content
        raise Sass::SyntaxError.new(%(Mixin "#{node.name}" does not accept a content block.))
      end

      args = node.args.map {|a| a.perform(@environment)}
      keywords = Sass::Util.map_vals(node.keywords) {|v| v.perform(@environment)}
      splat = self.class.perform_splat(node.splat, keywords, node.kwarg_splat, @environment)

      self.class.perform_arguments(mixin, args, splat, @environment) do |env|
        env.caller = Sass::Environment.new(@environment)
        env.content = [node.children, @environment] if node.has_children

        trace_node = Sass::Tree::TraceNode.from_node(node.name, node)
        with_environment(env) {trace_node.children = mixin.tree.map {|c| visit(c)}.flatten}
        trace_node
      end
    end
  rescue Sass::SyntaxError => e
    e.modify_backtrace(:mixin => node.name, :line => node.line)
    e.add_backtrace(:line => node.line)
    raise e
  end

  def visit_content(node)
    content, content_env = @environment.content
    return [] unless content
    @environment.stack.with_mixin(node.filename, node.line, '@content') do
      trace_node = Sass::Tree::TraceNode.from_node('@content', node)
      content_env = Sass::Environment.new(content_env)
      content_env.caller = Sass::Environment.new(@environment)
      with_environment(content_env) do
        trace_node.children = content.map {|c| visit(c.dup)}.flatten
      end
      trace_node
    end
  rescue Sass::SyntaxError => e
    e.modify_backtrace(:mixin => '@content', :line => node.line)
    e.add_backtrace(:line => node.line)
    raise e
  end

  # Runs any SassScript that may be embedded in a property.
  def visit_prop(node)
    node.resolved_name = run_interp(node.name)

    # If the node's value is just a variable or similar, we may get a useful
    # source range from evaluating it.
    if node.value.length == 1 && node.value.first.is_a?(Sass::Script::Tree::Node)
      result = node.value.first.perform(@environment)
      node.resolved_value = result.to_s
      node.value_source_range = result.source_range if result.source_range
    elsif node.custom_property?
      node.resolved_value = run_interp_no_strip(node.value)
    else
      node.resolved_value = run_interp(node.value)
    end

    yield
  end

  # Returns the value of the expression.
  def visit_return(node)
    throw :_sass_return, node.expr.perform(@environment)
  end

  # Runs SassScript interpolation in the selector,
  # and then parses the result into a {Sass::Selector::CommaSequence}.
  def visit_rule(node)
    old_at_root_without_rule = @at_root_without_rule
    parser = Sass::SCSS::StaticParser.new(run_interp(node.rule),
      node.filename, node.options[:importer], node.line)
    if @in_keyframes
      keyframe_rule_node = Sass::Tree::KeyframeRuleNode.new(parser.parse_keyframes_selector)
      keyframe_rule_node.options = node.options
      keyframe_rule_node.line = node.line
      keyframe_rule_node.filename = node.filename
      keyframe_rule_node.source_range = node.source_range
      keyframe_rule_node.has_children = node.has_children
      with_environment Sass::Environment.new(@environment, node.options) do
        keyframe_rule_node.children = node.children.map {|c| visit(c)}.flatten
      end
      keyframe_rule_node
    else
      @at_root_without_rule = false
      node.parsed_rules ||= parser.parse_selector
      node.resolved_rules = node.parsed_rules.resolve_parent_refs(
        @environment.selector, !old_at_root_without_rule)
      node.stack_trace = @environment.stack.to_s if node.options[:trace_selectors]
      with_environment Sass::Environment.new(@environment, node.options) do
        @environment.selector = node.resolved_rules
        node.children = node.children.map {|c| visit(c)}.flatten
      end
      node
    end
  ensure
    @at_root_without_rule = old_at_root_without_rule
  end

  # Sets a variable that indicates that the first level of rule nodes
  # shouldn't include the parent selector by default.
  def visit_atroot(node)
    if node.query
      parser = Sass::SCSS::StaticParser.new(run_interp(node.query),
        node.filename, node.options[:importer], node.line)
      node.resolved_type, node.resolved_value = parser.parse_static_at_root_query
    else
      node.resolved_type, node.resolved_value = :without, ['rule']
    end

    old_at_root_without_rule = @at_root_without_rule
    old_in_keyframes = @in_keyframes
    @at_root_without_rule = true if node.exclude?('rule')
    @in_keyframes = false if node.exclude?('keyframes')
    yield
  ensure
    @in_keyframes = old_in_keyframes
    @at_root_without_rule = old_at_root_without_rule
  end

  # Loads the new variable value into the environment.
  def visit_variable(node)
    env = @environment
    env = env.global_env if node.global
    if node.guarded
      var = env.var(node.name)
      return [] if var && !var.null?
    end

    val = node.expr.perform(@environment)
    if node.expr.source_range
      val.source_range = node.expr.source_range
    else
      val.source_range = node.source_range
    end
    env.set_var(node.name, val)
    []
  end

  # Prints the expression to STDERR with a stylesheet trace.
  def visit_warn(node)
    res = node.expr.perform(@environment)
    res = res.value if res.is_a?(Sass::Script::Value::String)
    @environment.stack.with_directive(node.filename, node.line, "@warn") do
      msg = "WARNING: #{res}\n         "
      msg << @environment.stack.to_s.gsub("\n", "\n         ") << "\n"
      Sass::Util.sass_warn msg
    end
    []
  end

  # Runs the child nodes until the continuation expression becomes false.
  def visit_while(node)
    children = []
    with_environment Sass::SemiGlobalEnvironment.new(@environment) do
      children += node.children.map {|c| visit(c)} while node.expr.perform(@environment).to_bool
    end
    children.flatten
  end

  def visit_directive(node)
    node.resolved_value = run_interp(node.value)
    old_in_keyframes, @in_keyframes = @in_keyframes, node.normalized_name == "@keyframes"
    with_environment Sass::Environment.new(@environment) do
      node.children = node.children.map {|c| visit(c)}.flatten
      node
    end
  ensure
    @in_keyframes = old_in_keyframes
  end

  def visit_media(node)
    parser = Sass::SCSS::StaticParser.new(run_interp(node.query),
      node.filename, node.options[:importer], node.line)
    node.resolved_query ||= parser.parse_media_query_list
    yield
  end

  def visit_supports(node)
    node.condition = node.condition.deep_copy
    node.condition.perform(@environment)
    yield
  end

  def visit_cssimport(node)
    node.resolved_uri = run_interp([node.uri])
    if node.query && !node.query.empty?
      parser = Sass::SCSS::StaticParser.new(run_interp(node.query),
        node.filename, node.options[:importer], node.line)
      node.resolved_query ||= parser.parse_media_query_list
    end
    if node.supports_condition
      node.supports_condition.perform(@environment)
    end
    yield
  end

  private

  def run_interp_no_strip(text)
    text.map do |r|
      next r if r.is_a?(String)
      r.perform(@environment).to_s(:quote => :none)
    end.join
  end

  def run_interp(text)
    Sass::Util.strip_except_escapes(run_interp_no_strip(text))
  end

  def handle_import_loop!(node)
    msg = "An @import loop has been found:"
    files = @environment.stack.frames.select {|f| f.is_import?}.map {|f| f.filename}.compact
    if node.filename == node.imported_file.options[:filename]
      raise Sass::SyntaxError.new("#{msg} #{node.filename} imports itself")
    end

    files << node.filename << node.imported_file.options[:filename]
    msg << "\n" << files.each_cons(2).map do |m1, m2|
      "    #{m1} imports #{m2}"
    end.join("\n")
    raise Sass::SyntaxError.new(msg)
  end
end
