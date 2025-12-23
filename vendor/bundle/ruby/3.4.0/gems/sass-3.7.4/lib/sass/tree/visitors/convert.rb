# A visitor for converting a Sass tree into a source string.
class Sass::Tree::Visitors::Convert < Sass::Tree::Visitors::Base
  # Runs the visitor on a tree.
  #
  # @param root [Tree::Node] The root node of the Sass tree.
  # @param options [{Symbol => Object}] An options hash (see {Sass::CSS#initialize}).
  # @param format [Symbol] `:sass` or `:scss`.
  # @return [String] The Sass or SCSS source for the tree.
  def self.visit(root, options, format)
    new(options, format).send(:visit, root)
  end

  protected

  def initialize(options, format)
    @options = options
    @format = format
    @tabs = 0
    # 2 spaces by default
    @tab_chars = @options[:indent] || "  "
    @is_else = false
  end

  def visit_children(parent)
    @tabs += 1
    return @format == :sass ? "\n" : " {}\n" if parent.children.empty?

    res = visit_rule_level(parent.children)

    if @format == :sass
      "\n" + res.rstrip + "\n"
    else
      " {\n" + res.rstrip + "\n#{@tab_chars * (@tabs - 1)}}\n"
    end
  ensure
    @tabs -= 1
  end

  # Ensures proper spacing between top-level nodes.
  def visit_root(node)
    visit_rule_level(node.children)
  end

  def visit_charset(node)
    "#{tab_str}@charset \"#{node.name}\"#{semi}\n"
  end

  def visit_comment(node)
    value = interp_to_src(node.value)
    if @format == :sass
      content = value.gsub(%r{\*/$}, '').rstrip
      if content =~ /\A[ \t]/
        # Re-indent SCSS comments like this:
        #     /* foo
        #   bar
        #       baz */
        content.gsub!(/^/, '   ')
        content.sub!(%r{\A([ \t]*)/\*}, '/*\1')
      end

      if content.include?("\n")
        content.gsub!(/\n \*/, "\n  ")
        spaces = content.scan(/\n( *)/).map {|s| s.first.size}.min
        sep = node.type == :silent ? "\n//" : "\n *"
        if spaces >= 2
          content.gsub!(/\n  /, sep)
        else
          content.gsub!(/\n#{' ' * spaces}/, sep)
        end
      end

      content.gsub!(%r{\A/\*}, '//') if node.type == :silent
      content.gsub!(/^/, tab_str)
      content = content.rstrip + "\n"
    else
      spaces = (@tab_chars * [@tabs - value[/^ */].size, 0].max)
      content = if node.type == :silent
                  value.gsub(%r{^[/ ]\*}, '//').gsub(%r{ *\*/$}, '')
                else
                  value
                end.gsub(/^/, spaces) + "\n"
    end
    content
  end

  def visit_debug(node)
    "#{tab_str}@debug #{node.expr.to_sass(@options)}#{semi}\n"
  end

  def visit_error(node)
    "#{tab_str}@error #{node.expr.to_sass(@options)}#{semi}\n"
  end

  def visit_directive(node)
    res = "#{tab_str}#{interp_to_src(node.value)}"
    res.gsub!(/^@import \#\{(.*)\}([^}]*)$/, '@import \1\2')
    return res + "#{semi}\n" unless node.has_children
    res + yield
  end

  def visit_each(node)
    vars = node.vars.map {|var| "$#{dasherize(var)}"}.join(", ")
    "#{tab_str}@each #{vars} in #{node.list.to_sass(@options)}#{yield}"
  end

  def visit_extend(node)
    "#{tab_str}@extend #{selector_to_src(node.selector).lstrip}" +
      "#{' !optional' if node.optional?}#{semi}\n"
  end

  def visit_for(node)
    "#{tab_str}@for $#{dasherize(node.var)} from #{node.from.to_sass(@options)} " +
      "#{node.exclusive ? 'to' : 'through'} #{node.to.to_sass(@options)}#{yield}"
  end

  def visit_function(node)
    args = node.args.map do |v, d|
      d ? "#{v.to_sass(@options)}: #{d.to_sass(@options)}" : v.to_sass(@options)
    end.join(", ")
    if node.splat
      args << ", " unless node.args.empty?
      args << node.splat.to_sass(@options) << "..."
    end

    "#{tab_str}@function #{dasherize(node.name)}(#{args})#{yield}"
  end

  def visit_if(node)
    name =
      if !@is_else
        "if"
      elsif node.expr
        "else if"
      else
        "else"
      end
    @is_else = false
    str = "#{tab_str}@#{name}"
    str << " #{node.expr.to_sass(@options)}" if node.expr
    str << yield
    @is_else = true
    str << visit(node.else) if node.else
    str
  ensure
    @is_else = false
  end

  def visit_import(node)
    quote = @format == :scss ? '"' : ''
    "#{tab_str}@import #{quote}#{node.imported_filename}#{quote}#{semi}\n"
  end

  def visit_media(node)
    "#{tab_str}@media #{query_interp_to_src(node.query)}#{yield}"
  end

  def visit_supports(node)
    "#{tab_str}@#{node.name} #{node.condition.to_src(@options)}#{yield}"
  end

  def visit_cssimport(node)
    if node.uri.is_a?(Sass::Script::Tree::Node)
      str = "#{tab_str}@import #{node.uri.to_sass(@options)}"
    else
      str = "#{tab_str}@import #{node.uri}"
    end
    str << " supports(#{node.supports_condition.to_src(@options)})" if node.supports_condition
    str << " #{interp_to_src(node.query)}" unless node.query.empty?
    "#{str}#{semi}\n"
  end

  def visit_mixindef(node)
    args =
      if node.args.empty? && node.splat.nil?
        ""
      else
        str = '('
        str << node.args.map do |v, d|
          if d
            "#{v.to_sass(@options)}: #{d.to_sass(@options)}"
          else
            v.to_sass(@options)
          end
        end.join(", ")

        if node.splat
          str << ", " unless node.args.empty?
          str << node.splat.to_sass(@options) << '...'
        end

        str << ')'
      end

    "#{tab_str}#{@format == :sass ? '=' : '@mixin '}#{dasherize(node.name)}#{args}#{yield}"
  end

  def visit_mixin(node)
    arg_to_sass = lambda do |arg|
      sass = arg.to_sass(@options)
      sass = "(#{sass})" if arg.is_a?(Sass::Script::Tree::ListLiteral) && arg.separator == :comma
      sass
    end

    unless node.args.empty? && node.keywords.empty? && node.splat.nil?
      args = node.args.map(&arg_to_sass)
      keywords = node.keywords.as_stored.to_a.map {|k, v| "$#{dasherize(k)}: #{arg_to_sass[v]}"}

      if node.splat
        splat = "#{arg_to_sass[node.splat]}..."
        kwarg_splat = "#{arg_to_sass[node.kwarg_splat]}..." if node.kwarg_splat
      end

      arglist = "(#{[args, splat, keywords, kwarg_splat].flatten.compact.join(', ')})"
    end
    "#{tab_str}#{@format == :sass ? '+' : '@include '}" +
      "#{dasherize(node.name)}#{arglist}#{node.has_children ? yield : semi}\n"
  end

  def visit_content(node)
    "#{tab_str}@content#{semi}\n"
  end

  def visit_prop(node)
    res = tab_str + node.declaration(@options, @format)
    return res + semi + "\n" if node.children.empty?
    res + yield.rstrip + semi + "\n"
  end

  def visit_return(node)
    "#{tab_str}@return #{node.expr.to_sass(@options)}#{semi}\n"
  end

  def visit_rule(node)
    rule = node.parsed_rules ? [node.parsed_rules.to_s] : node.rule
    if @format == :sass
      name = selector_to_sass(rule)
      name = "\\" + name if name[0] == ?:
      name.gsub(/^/, tab_str) + yield
    elsif @format == :scss
      name = selector_to_scss(rule)
      res = name + yield
      if node.children.last.is_a?(Sass::Tree::CommentNode) && node.children.last.type == :silent
        res.slice!(-3..-1)
        res << "\n" << tab_str << "}\n"
      end
      res
    end
  end

  def visit_variable(node)
    "#{tab_str}$#{dasherize(node.name)}: #{node.expr.to_sass(@options)}" +
      "#{' !global' if node.global}#{' !default' if node.guarded}#{semi}\n"
  end

  def visit_warn(node)
    "#{tab_str}@warn #{node.expr.to_sass(@options)}#{semi}\n"
  end

  def visit_while(node)
    "#{tab_str}@while #{node.expr.to_sass(@options)}#{yield}"
  end

  def visit_atroot(node)
    if node.query
      "#{tab_str}@at-root #{query_interp_to_src(node.query)}#{yield}"
    elsif node.children.length == 1 && node.children.first.is_a?(Sass::Tree::RuleNode)
      rule = node.children.first
      "#{tab_str}@at-root #{selector_to_src(rule.rule).lstrip}#{visit_children(rule)}"
    else
      "#{tab_str}@at-root#{yield}"
    end
  end

  def visit_keyframerule(node)
    "#{tab_str}#{node.resolved_value}#{yield}"
  end

  private

  # Visit rule-level nodes and return their conversion with appropriate
  # whitespace added.
  def visit_rule_level(nodes)
    (nodes + [nil]).each_cons(2).map do |child, nxt|
      visit(child) +
        if nxt &&
            (child.is_a?(Sass::Tree::CommentNode) && child.line + child.lines + 1 == nxt.line) ||
            (child.is_a?(Sass::Tree::ImportNode) && nxt.is_a?(Sass::Tree::ImportNode) &&
              child.line + 1 == nxt.line) ||
            (child.is_a?(Sass::Tree::VariableNode) && nxt.is_a?(Sass::Tree::VariableNode) &&
              child.line + 1 == nxt.line) ||
            (child.is_a?(Sass::Tree::PropNode) && nxt.is_a?(Sass::Tree::PropNode)) ||
            (child.is_a?(Sass::Tree::MixinNode) && nxt.is_a?(Sass::Tree::MixinNode) &&
              child.line + 1 == nxt.line)
          ""
        else
          "\n"
        end
    end.join.rstrip + "\n"
  end

  def interp_to_src(interp)
    interp.map {|r| r.is_a?(String) ? r : r.to_sass(@options)}.join
  end

  # Like interp_to_src, but removes the unnecessary `#{}` around the keys and
  # values in query expressions.
  def query_interp_to_src(interp)
    interp = interp.map do |e|
      next e unless e.is_a?(Sass::Script::Tree::Literal)
      next e unless e.value.is_a?(Sass::Script::Value::String)
      e.value.value
    end

    interp_to_src(interp)
  end

  def selector_to_src(sel)
    @format == :sass ? selector_to_sass(sel) : selector_to_scss(sel)
  end

  def selector_to_sass(sel)
    sel.map do |r|
      if r.is_a?(String)
        r.gsub(/(,)?([ \t]*)\n\s*/) {$1 ? "#{$1}#{$2}\n" : " "}
      else
        r.to_sass(@options)
      end
    end.join
  end

  def selector_to_scss(sel)
    interp_to_src(sel).gsub(/^[ \t]*/, tab_str).gsub(/[ \t]*$/, '')
  end

  def semi
    @format == :sass ? "" : ";"
  end

  def tab_str
    @tab_chars * @tabs
  end

  def dasherize(s)
    if @options[:dasherize]
      s.tr('_', '-')
    else
      s
    end
  end
end
