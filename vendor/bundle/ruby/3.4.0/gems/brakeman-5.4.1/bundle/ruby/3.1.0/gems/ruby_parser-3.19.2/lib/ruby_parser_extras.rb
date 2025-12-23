# encoding: ASCII-8BIT
# frozen_string_literal: true
# TODO: remove encoding comment

require "sexp"
require "ruby_lexer"
require "timeout"
require "rp_extensions"
require "rp_stringscanner"

class Sexp
  def check_line_numbers
    raise "bad nil line for:\n%s" % [self.pretty_inspect] if nil_line?
    raise "bad line number for:\n%s" % [self.pretty_inspect] unless
      Integer === self.line &&
      self.line >= 1 &&
      self.line <= self.line_min
  end

  ##
  # Returns the maximum line number of the children of self.

  def line_min
    @line_min ||= [self.deep_each.map(&:line).min, self.line].compact.min
  end

  def nil_line?
    self.deep_each.map(&:line).any?(&:nil?)
  end
end

module RubyParserStuff
  VERSION = "3.19.2"

  attr_accessor :lexer, :in_def, :in_single, :file
  attr_accessor :in_kwarg
  attr_reader :env, :comments

  ##
  # Canonicalize conditionals. Eg:
  #
  #   not x ? a : b
  #
  # becomes:
  #
  #   x ? b : a

  attr_accessor :canonicalize_conditions

  ##
  # The last token type returned from #next_token

  attr_accessor :last_token_type

  $good20 = []

  %w[
  ].map(&:to_i).each do |n|
    $good20[n] = n
  end

  def debug20 n, v = nil, r = nil
    raise "not yet #{n} #{v.inspect} => #{r.inspect}" unless $good20[n]
  end

  def self.deprecate old, new
    define_method old do |*args|
      warn "DEPRECATED: #{old} -> #{new} from #{caller.first}"
      send new, *args
    end
  end

  ##
  # for pure ruby systems only

  def do_parse
    _racc_do_parse_rb(_racc_setup, false)
  end if ENV["PURE_RUBY"] || ENV["CHECK_LINE_NUMS"]

  if ENV["CHECK_LINE_NUMS"] then
    def _racc_do_reduce arg, act
      x = super

      @racc_vstack.grep(Sexp).each do |sexp|
        sexp.check_line_numbers
      end
      x
    end
  end

  ARG_TYPES = [:arglist, :call_args, :array, :args].map { |k|
    [k, true]
  }.to_h

  has_enc = "".respond_to? :encoding

  # This is in sorted order of occurrence according to
  # charlock_holmes against 500k files, with UTF_8 forced
  # to the top.
  #
  # Overwrite this contstant if you need something different.
  ENCODING_ORDER = [
    Encoding::UTF_8, # moved to top to reflect default in 2.0
    Encoding::ISO_8859_1,
    Encoding::ISO_8859_2,
    Encoding::ISO_8859_9,
    Encoding::SHIFT_JIS,
    Encoding::WINDOWS_1252,
    Encoding::EUC_JP
  ] if has_enc

  JUMP_TYPE = [:return, :next, :break, :yield].map { |k| [k, true] }.to_h

  TAB_WIDTH = 8

  def initialize(options = {})
    super()

    v = self.class.name[/[23]\d/]
    raise "Bad Class name #{self.class}" unless v

    self.lexer = RubyLexer.new v && v.to_i
    self.lexer.parser = self
    self.in_kwarg = false

    @env = RubyParserStuff::Environment.new
    @comments = []

    @canonicalize_conditions = true

    self.reset
  end

  def arg_concat node1, node2 # TODO: nuke
    raise "huh" unless node2

    splat = s(:splat, node2)
    splat.line node2.line

    node1 << splat
  end

  def argl x
    x = s(:arglist, x) if x and x.sexp_type == :array
    x
  end

  def args args
    result = s(:args)

    ss = args.grep Sexp
    if ss.empty? then
      result.line lexer.lineno
    else
      result.line ss.first.line
    end

    args.each do |arg|
      if arg.instance_of? Array and arg.size == 2 and arg.last.is_a? Numeric then
        arg = arg.first
      end

      case arg
      when Sexp then
        case arg.sexp_type
        when :args, :block, :array, :call_args then # HACK call_args mismatch
          rest = arg.sexp_body

          rest.map! { |x|
            if x.instance_of? Array and x.size == 2 and Numeric === x.last then
              x.first
            else
              x
            end
          }

          result.concat rest
        when :forward_args then
          self.env[:*]  = :lvar # TODO: arg_var(p, idFWD_REST) ?
          self.env[:**] = :lvar
          self.env[:&]  = :lvar

          result << arg
        when :block_arg then
          result << :"&#{arg.last}"
        when :shadow then
          name = arg.last
          self.env[name] = :lvar
          if Sexp === result.last and result.last.sexp_type == :shadow then
            result.last << name
          else
            result << arg
          end
        when :masgn, :block_pass, :hash then # HACK: remove. prolly call_args
          result << arg
        else
          raise "unhandled: #{arg.sexp_type} in #{args.inspect}"
        end
      when Symbol then
        name = arg.to_s.delete("&*")
        self.env[name.to_sym] = :lvar unless name.empty?
        result << arg
      when true, false then
        self.in_kwarg = arg
      when ",", "|", ";", "(", ")", nil then
        # ignore
      else
        raise "unhandled: #{arg.inspect} in #{args.inspect}"
      end
    end

    result
  end

  def end_args args
    lexer.lex_state     = RubyLexer::State::Values::EXPR_BEG
    lexer.command_start = true
    self.args args
  end

  def attrset_id? id
    id =~ /^\[\]=$|^\w+=$/
  end

  def endless_method_name defn_or_defs
    name = defn_or_defs[1]
    name = defn_or_defs[2] unless Symbol === name

    if attrset_id? name then
      yyerror "setter method cannot be defined in an endless method definition"
    end

    # TODO? token_info_drop(p, "def", loc->beg_pos);
  end

  def array_to_hash array
    case array.sexp_type
    when :kwsplat then
      array
    else
      s(:hash, *array.sexp_body).line array.line
    end
  end

  def aryset receiver, index
    index ||= s()
    l = receiver.line
    result = s(:attrasgn, receiver, :"[]=",
               *index.sexp_body).compact # [].sexp_body => nil
    result.line = l
    result
  end

  def assignable(lhs, value = nil)
    id, line = lhs
    id = id.to_sym

    result = case id
             when /^@@/ then
               asgn = in_def || in_single > 0
               s((asgn ? :cvasgn : :cvdecl), id)
             when /^@/ then
               s(:iasgn, id)
             when /^\$/ then
               s(:gasgn, id)
             when /^[A-Z]/ then
               s(:cdecl, id)
             else
               case self.env[id]
               when :lvar, :dvar, nil then
                 s(:lasgn, id)
               else
                 raise "wtf? unknown type: #{self.env[id]}"
               end
             end

    self.env[id] ||= :lvar if result.sexp_type == :lasgn

    result << value if value
    result.line line
    result
  end

  def backref_assign_error ref
    # TODO: need a test for this... obviously
    case ref.sexp_type
    when :nth_ref then
      raise "write a test 2"
      raise SyntaxError, "Can't set variable %p" % ref.last
    when :back_ref then
      raise "write a test 3"
      raise SyntaxError, "Can't set back reference %p" % ref.last
    else
      raise "Unknown backref type: #{ref.inspect}"
    end
  end

  def block_append(head, tail)
    return head if tail.nil?
    return tail if head.nil?

    line = [head.line, tail.line].compact.min

    head = remove_begin(head)
    head = s(:block, head).line(line) unless head.sexp_type == :block

    # head.line = line
    head << tail
  end

  def block_dup_check call_or_args, block
    syntax_error "Both block arg and actual block given." if
      block and call_or_args.block_pass?
  end

  def block_var *args
    result = self.args args
    result.sexp_type = :masgn
    result
  end

  def call_args args
    result = s(:call_args)

    a = args.grep(Sexp).first
    if a then
      result.line a.line
    else
      result.line lexer.lineno
    end

    args.each do |arg|
      if arg.instance_of? Array and arg.size == 2 and arg.last.is_a? Numeric then
        arg = arg.first
      end

      case arg
      when Sexp then
        case arg.sexp_type
        when :array, :args, :call_args then # HACK? remove array at some point
          result.concat arg.sexp_body
        else
          result << arg
        end
      when Symbol then
        result << arg
      when Array then
        id, _line = arg
        result << id
      when ",", nil, "(" then
        # ignore
      else
        raise "unhandled: #{arg.inspect} in #{args.inspect}"
      end
    end

    result
  end

  def clean_mlhs sexp
    case sexp.sexp_type
    when :masgn then
      if sexp.size == 2 and sexp[1].sexp_type == :array then
        s(:masgn, *sexp[1].sexp_body.map { |sub| clean_mlhs sub })
      else
        debug20 5
        sexp
      end
    when :gasgn, :iasgn, :lasgn, :cvasgn then
      if sexp.size == 2 then
        sexp.last
      else
        debug20 7
        sexp # optional value
      end
    else
      raise "unsupported type: #{sexp.inspect}"
    end
  end

  def cond node
    return nil if node.nil?
    node = value_expr node

    case node.sexp_type
    when :lit then
      if Regexp === node.last then
        s(:match, node)
      else
        node
      end
    when :and then
      _, lhs, rhs = node
      s(:and,  cond(lhs), cond(rhs))
    when :or then
      _, lhs, rhs = node
      s(:or,  cond(lhs), cond(rhs))
    when :dot2 then
      label = "flip#{node.hash}"
      env[label] = :lvar
      _, lhs, rhs = node
      s(:flip2, lhs, rhs) # TODO: recurse?
    when :dot3 then
      label = "flip#{node.hash}"
      env[label] = :lvar
      _, lhs, rhs = node
      s(:flip3, lhs, rhs)
    else
      node
    end.line node.line
  end

  def dedent sexp
    dedent_count = dedent_size sexp

    skip_one = false
    sexp.map { |obj|
      case obj
      when Symbol then
        obj
      when String then
        obj.lines.map { |l| remove_whitespace_width l, dedent_count }.join
      when Sexp then
        case obj.sexp_type
        when :evstr then
          skip_one = true
          obj
        when :str then
          _, str = obj
          str = if skip_one then
                  skip_one = false
                  s1, *rest = str.lines
                  s1 + rest.map { |l| remove_whitespace_width l, dedent_count }.join
                else
                  str.lines.map { |l| remove_whitespace_width l, dedent_count }.join
                end

          s(:str, str).line obj.line
        else
          warn "unprocessed sexp %p" % [obj]
        end
      else
        warn "unprocessed: %p" % [obj]
      end
    }
  end

  def dedent_size sexp
    skip_one = false
    sexp.flat_map { |s|
      case s
      when Symbol then
        next
      when String then
        s.lines
      when Sexp then
        case s.sexp_type
        when :evstr then
          skip_one = true
          next
        when :str then
          _, str = s
          lines = str.lines
          if skip_one then
            skip_one = false
            lines.shift
          end
          lines
        else
          warn "unprocessed sexp %p" % [s]
        end
      else
        warn "unprocessed: %p" % [s]
      end.map { |l| whitespace_width l }
    }.compact.min
  end

  def dedent_string string, width
    characters_skipped = 0
    indentation_skipped = 0

    string.chars.each do |char|
      break if indentation_skipped >= width
      if char == " "
        characters_skipped += 1
        indentation_skipped += 1
      elsif char == "\t"
        proposed = TAB_WIDTH * (indentation_skipped / TAB_WIDTH + 1)
        break if proposed > width
        characters_skipped += 1
        indentation_skipped = proposed
      end
    end
    string[characters_skipped..-1]
  end

  def gettable(id)
    id = id.to_sym if String === id

    result = case id.to_s
             when /^@@/ then
               s(:cvar, id)
             when /^@/ then
               s(:ivar, id)
             when /^\$/ then
               s(:gvar, id)
             when /^[A-Z]/ then
               s(:const, id)
             else
               type = env[id]
               if type then
                 s(type, id)
               else
                 new_call(nil, id)
               end
             end

    raise "identifier #{id.inspect} is not valid" unless result

    result
  end

  def hack_encoding str, extra = nil
    encodings = ENCODING_ORDER.dup
    encodings.unshift(extra) unless extra.nil?

    # terrible, horrible, no good, very bad, last ditch effort.
    encodings.each do |enc|
      begin
        str.force_encoding enc
        if str.valid_encoding? then
          str.encode! Encoding::UTF_8
          break
        end
      rescue ArgumentError # unknown encoding name
        # do nothing
      rescue Encoding::InvalidByteSequenceError
        # do nothing
      rescue Encoding::UndefinedConversionError
        # do nothing
      end
    end

    # no amount of pain is enough for you.
    raise "Bad encoding. Need a magic encoding comment." unless
      str.encoding.name == "UTF-8"
  end

  ##
  # Returns a UTF-8 encoded string after processing BOMs and magic
  # encoding comments.
  #
  # Holy crap... ok. Here goes:
  #
  # Ruby's file handling and encoding support is insane. We need to be
  # able to lex a file. The lexer file is explicitly UTF-8 to make
  # things cleaner. This allows us to deal with extended chars in
  # class and method names. In order to do this, we need to encode all
  # input source files as UTF-8. First, we look for a UTF-8 BOM by
  # looking at the first line while forcing its encoding to
  # ASCII-8BIT. If we find a BOM, we strip it and set the expected
  # encoding to UTF-8. Then, we search for a magic encoding comment.
  # If found, it overrides the BOM. Finally, we force the encoding of
  # the input string to whatever was found, and then encode that to
  # UTF-8 for compatibility with the lexer.

  def handle_encoding str
    str = str.dup
    has_enc = str.respond_to? :encoding
    encoding = nil

    header = str.each_line.first(2)
    header.map! { |s| s.force_encoding "ASCII-8BIT" } if has_enc

    first = header.first || ""
    encoding, str = +"utf-8", str.b[3..-1] if first =~ /\A\xEF\xBB\xBF/

    encoding = $1.strip if header.find { |s|
      s[/^#.*?-\*-.*?coding:\s*([^ ;]+).*?-\*-/, 1] ||
      s[/^#.*(?:en)?coding(?:\s*[:=])\s*([\w-]+)/, 1]
    }

    if encoding then
      if has_enc then
        encoding.sub!(/utf-8-.+$/, "utf-8") # HACK for stupid emacs formats
        hack_encoding str, encoding
      else
        warn "Skipping magic encoding comment"
      end
    else
      # nothing specified... ugh. try to encode as utf-8
      hack_encoding str if has_enc
    end

    str
  end

  def invert_block_call val
    ret, iter = val
    type, call = ret

    iter.insert 1, call

    ret = s(type).line ret.line

    [iter, ret]
  end

  def inverted? val
    JUMP_TYPE[val[0].sexp_type]
  end

  def list_append list, item # TODO: nuke me *sigh*
    return s(:array, item) unless list
    list = s(:array, list) unless Sexp === list && list.sexp_type == :array
    list << item
  end

  def list_prepend item, list # TODO: nuke me *sigh*
    list = s(:array, list) unless Sexp === list && list.sexp_type == :array
    list.insert 1, item
    list
  end

  def literal_concat head, tail # TODO: ugh. rewrite
    return tail unless head
    return head unless tail

    htype, ttype = head.sexp_type, tail.sexp_type

    head = s(:dstr, "", head).line head.line if htype == :evstr

    case ttype
    when :str then
      if htype == :str
        a, b = head.last, tail.last
        b = b.dup.force_encoding a.encoding unless Encoding.compatible?(a, b)
        a << b
      elsif htype == :dstr and head.size == 2 then
        head.last << tail.last
      else
        head << tail
      end
    when :dstr then
      if htype == :str then
        lineno = head.line
        tail[1] = head.last + tail[1]
        head = tail
        head.line = lineno
      else
        tail.sexp_type = :array
        tail[1] = s(:str, tail[1]).line tail.line
        tail.delete_at 1 if tail[1] == s(:str, "")

        head.push(*tail.sexp_body)
      end
    when :evstr then
      if htype == :str then
        f, l = head.file, head.line
        head = s(:dstr, *head.sexp_body)
        head.file = f
        head.line = l
      end

      if head.size == 2 and tail.size > 1 and tail[1].sexp_type == :str then
        head.last << tail[1].last
        head.sexp_type = :str if head.size == 2 # HACK ?
      else
        head.push(tail)
      end
    else
      x = [head, tail]
      raise "unknown type: #{x.inspect}"
    end

    return head
  end

  def local_pop in_def
    lexer.cond.pop # group = local_pop
    lexer.cmdarg.pop
    self.env.unextend
    self.in_def = in_def
  end

  def logical_op type, left, right
    left = value_expr left

    if left and left.sexp_type == type and not left.paren then
      node, rhs = left, nil

      loop do
        _, _lhs, rhs = node
        break unless rhs && rhs.sexp_type == type and not rhs.paren
        node = rhs
      end

      node.pop
      node << s(type, rhs, right).line(rhs.line)

      return left
    end

    result = s(type, left, right)
    result.line left.line if left.line
    result
  end

  def new_aref val
    val[2] ||= s(:arglist)
    val[2].sexp_type = :arglist if val[2].sexp_type == :array # REFACTOR
    new_call val[0], :"[]", val[2]
  end

  def new_arg val
    arg, = val

    case arg
    when Symbol then
      result = s(:args, arg).line line
    when Sexp then
      result = arg
    when Array then
      (arg, line), = val
      result = s(:args, arg).line line
    else
      debug20 32
      raise "Unknown f_arg type: #{val.inspect}"
    end

    result
  end

  def ary_to_pat ary
    pat = ary.dup
    pat.sexp_type = :array_TAIL

    new_array_pattern nil, nil, pat, ary.line
  end

  def new_array_pattern const, pre_arg, arypat, loc
    result = s(:array_pat, const).line loc
    result << pre_arg if pre_arg

    if arypat && arypat.sexp_type == :array_TAIL then
      result.concat arypat.sexp_body
    else
      raise "NO?: %p" % [arypat]
    end

    result
  end

  def array_pat_concat lhs, rhs
    case lhs.sexp_type
    when :PATTERN then
      lhs.sexp_type = :array_pat
    end

    if rhs then
      case rhs.sexp_type
      when :array_pat, :array_TAIL, :PATTERN then
        lhs.concat rhs.sexp_body
      else
        lhs << rhs
      end
    end
  end

  def new_array_pattern_tail pre_args, has_rest, rest_arg, post_args
    # TODO: remove has_rest once all tests pass !!!
    rest_arg = if has_rest then
                 :"*#{rest_arg}"
               else
                 nil
               end

    result = s(:array_TAIL).line 666

    array_pat_concat result, pre_args

    result << rest_arg if rest_arg

    array_pat_concat result, post_args

    result
  end

  def new_assign lhs, rhs
    return nil unless lhs

    rhs = value_expr rhs

    case lhs.sexp_type
    when :lasgn, :iasgn, :cdecl, :cvdecl, :gasgn, :cvasgn, :attrasgn, :safe_attrasgn then
      lhs << rhs
    when :const then
      lhs.sexp_type = :cdecl
      lhs << rhs
    else
      raise "unknown lhs #{lhs.inspect} w/ #{rhs.inspect}"
    end

    lhs
  end

  def new_attrasgn recv, meth, call_op = :"."
    call_op = call_op.first if Array === call_op

    meth = :"#{meth}="

    result = case call_op.to_sym
             when :"."
               s(:attrasgn, recv, meth)
             when :"&."
               s(:safe_attrasgn, recv, meth)
             else
               raise "unknown call operator: `#{type.inspect}`"
             end

    result.line = recv.line
    result
  end

  def new_begin val
    _, lineno, body, _ = val

    result = body ? s(:begin, body) : s(:nil)
    result.line lineno

    result
  end

  def new_body val
    body, resbody, elsebody, ensurebody = val

    result = body

    if resbody then
      result = s(:rescue)
      result << body if body

      res = resbody

      while res do
        result << res
        res = res.resbody(true)
      end

      result << elsebody if elsebody

      result.line = (body || resbody).line
    end

    if elsebody and not resbody then
      warning("else without rescue is useless")
      result = s(:begin, result).line result.line if result
      result = block_append(result, elsebody)
    end

    if ensurebody
      lineno = (result || ensurebody).line
      result = s(:ensure, result, ensurebody).compact.line lineno
    end

    result
  end

  def new_brace_body args, body, lineno
    new_iter(nil, args, body).line lineno
  end

  def new_call recv, meth, args = nil, call_op = :"."
    call_op = call_op.first if Array === call_op

    result = case call_op.to_sym
             when :"."
               s(:call, recv, meth)
             when :"&."
               s(:safe_call, recv, meth)
             else
               raise "unknown call operator: `#{type.inspect}`"
             end

    # TODO: need a test with f(&b) to produce block_pass
    # TODO: need a test with f(&b) { } to produce warning

    if args
      if ARG_TYPES[args.sexp_type] then
        result.concat args.sexp_body
      else
        result << args
      end
    end

    # line = result.grep(Sexp).map(&:line).compact.min
    result.line = recv.line if recv
    result.line ||= lexer.lineno

    result
  end

  def new_in pat, body, cases, line
    s(:in, pat, body, cases).line line
  end

  def new_case expr, body, line
    result = s(:case, expr)

    while body and [:when, :in].include? body.sexp_type
      result << body
      body = body.delete_at 3
    end

    result[2..-1].each do |node|
      block = node.block(:delete)
      node.concat block.sexp_body if block
    end

    # else
    body = nil if body == s(:block)
    result << body

    result.line = line
    result
  end

  def new_class val
    # TODO: get line from class keyword
    line, path, superclass, body = val[1], val[2], val[3], val[5]

    path = path.first if path.instance_of? Array

    result = s(:class, path, superclass)

    if body then
      if body.sexp_type == :block then
        result.push(*body.sexp_body)
      else
        result.push body
      end
    end

    result.line = line
    result.comments = self.comments.pop
    result
  end

  def new_compstmt val
    result = void_stmts(val.grep(Sexp)[0])
    result = remove_begin(result) if result
    result
  end

  def new_const_op_asgn val
    lhs, (asgn_op, _), rhs = val
    asgn_op = asgn_op.to_sym

    result = case asgn_op
             when :"||" then
               s(:op_asgn_or, lhs, rhs)
             when :"&&" then
               s(:op_asgn_and, lhs, rhs)
             else
               s(:op_asgn, lhs, asgn_op, rhs)
             end

    result.line = lhs.line
    result
  end

  def new_defn val
    _, (name, line), in_def, args, body, _ = val

    body ||= s(:nil).line line

    args.line line

    result = s(:defn, name.to_sym, args).line line

    if body.sexp_type == :block then
      result.push(*body.sexp_body)
    else
      result.push body
    end

    result.comments = self.comments.pop

    [result, in_def]
  end

  def new_endless_defn val
    (name, line, in_def), args, _, body, _, resbody = val

    result =
      if resbody then
        s(:defn, name, args,
          new_rescue(body,
                     new_resbody(s(:array).line(line),
                                 resbody))).line line
      else
        s(:defn, name, args, body).line line
      end

    local_pop in_def
    endless_method_name result

    result.comments = self.comments.pop

    result
  end

  def new_endless_defs val
    (recv, (name, line, in_def)), args, _, body, _, resbody = val

    result =
      if resbody then
        s(:defs, recv, name, args,
          new_rescue(body,
                     new_resbody(s(:array).line(line),
                                 resbody))).line line
      else
        s(:defs, recv, name, args, body).line(line)
      end

    self.in_single -= 1
    local_pop in_def
    endless_method_name result

    result.comments = self.comments.pop

    result
  end

  def new_defs val
    _, recv, (name, line), in_def, args, body, _ = val

    body ||= s(:nil).line line

    args.line line

    result = s(:defs, recv, name.to_sym, args).line line

    # TODO: remove_begin
    # TODO: reduce_nodes

    if body.sexp_type == :block then
      result.push(*body.sexp_body)
    else
      result.push body
    end

    result.comments = self.comments.pop

    [result, in_def]
  end

  def new_do_body args, body, lineno
    new_iter(nil, args, body).line(lineno)
  end

  def new_find_pattern const, pat
    pat.sexp_type = :find_pat
    pat.insert 1, const
  end

  def new_find_pattern_tail lhs, mid, rhs
    lhs_id, line = lhs
    rhs_id, _line = rhs

    # TODO: fpinfo->pre_rest_arg = pre_rest_arg ? assignable(p, pre_rest_arg, 0, loc) : NODE_SPECIAL_NO_NAME_REST;

    lhs_id = "*#{lhs_id}".to_sym
    rhs_id = "*#{rhs_id}".to_sym

    raise "BAD?" unless mid.sexp_type == :array_TAIL

    s(:find_pat_TAIL, lhs_id, *mid.sexp_body, rhs_id).line line
  end

  def new_for expr, var, body
    result = s(:for, expr, var).line(var.line)
    result << body if body
    result
  end

  def new_hash val
    _, line, assocs = val

    s(:hash).line(line).concat assocs.sexp_body
  end

  def new_hash_pattern const, hash_pat, loc
    _, pat, kw_args, kw_rest_arg = hash_pat

    line = (const||hash_pat).line

    result = s(:hash_pat, const).line line
    result.concat pat.sexp_body if pat
    result << kw_args     if kw_args
    result << kw_rest_arg if kw_rest_arg
    result
  end

  def new_hash_pattern_tail kw_args, kw_rest_arg, line # TODO: remove line arg
    # kw_rest_arg = assignable(kw_rest_arg, nil).line line if kw_rest_arg

    result = s(:hash_pat).line line
    result << kw_args

    if kw_rest_arg then
      name = kw_rest_arg.value
      # TODO: I _hate_ this:
      assignable [name, kw_rest_arg.line] if name != :**
      result << kw_rest_arg
    end

    result
  end

  def push_pktbl
  end

  def pop_pktbl
  end

  def push_pvtbl
  end

  def pop_pvtbl
  end

  def new_if c, t, f
    l = [c.line, t && t.line, f && f.line].compact.min
    c = cond c
    c, t, f = c.last, f, t if c.sexp_type == :not and canonicalize_conditions
    s(:if, c, t, f).line(l)
  end

  def new_iter call, args, body
    body ||= nil

    args ||= s(:args)
    args = s(:args, args) if Symbol === args

    result = s(:iter)
    result << call if call
    result << args
    result << body if body

    result.line call.line if call

    unless args == 0 then
      args.line call.line if call
      args.sexp_type = :args
    end

    result
  end

  def new_masgn lhs, rhs, wrap = false
    _, ary = lhs

    line = rhs.line
    rhs = value_expr(rhs)
    rhs = ary ? s(:to_ary, rhs) : s(:array, rhs) if wrap
    rhs.line line if wrap

    lhs.delete_at 1 if ary.nil?
    lhs << rhs

    lhs
  end

  def new_masgn_arg rhs, wrap = false
    rhs = value_expr(rhs)
    # HACK: could be array if lhs isn't right
    rhs = s(:to_ary, rhs).line rhs.line if wrap
    rhs
  end

  def new_match lhs, rhs
    if lhs then
      case lhs.sexp_type
      when :dregx, :dregx_once then
        # TODO: no test coverage
        return s(:match2, lhs, rhs).line(lhs.line)
      when :lit then
        return s(:match2, lhs, rhs).line(lhs.line) if Regexp === lhs.last
      end
    end

    if rhs then
      case rhs.sexp_type
      when :dregx, :dregx_once then
        # TODO: no test coverage
        return s(:match3, rhs, lhs).line(lhs.line)
      when :lit then
        return s(:match3, rhs, lhs).line(lhs.line) if Regexp === rhs.last
      end
    end

    new_call(lhs, :"=~", argl(rhs)).line lhs.line
  end

  def new_module val
    # TODO: get line from module keyword
    line, path, body = val[1], val[2], val[4]

    path = path.first if path.instance_of? Array

    result = s(:module, path).line line

    if body then # REFACTOR?
      if body.sexp_type == :block then
        result.push(*body.sexp_body)
      else
        result.push body
      end
    end

    result.comments = self.comments.pop
    result
  end

  def new_op_asgn val
    lhs, (op, _line), rhs = val
    op = op.to_sym

    name = gettable(lhs.last).line lhs.line
    arg = remove_begin rhs
    result = case op # REFACTOR
             when :"||" then
               lhs << arg
               s(:op_asgn_or, name, lhs).line lhs.line
             when :"&&" then
               lhs << arg
               s(:op_asgn_and, name, lhs).line lhs.line
             else
               lhs << new_call(name, op, argl(arg))
               lhs
             end

    result
  end

  def new_op_asgn1 val
    lhs, _, args, _, (op, _), rhs = val

    args.sexp_type = :arglist if args

    result = s(:op_asgn1, lhs, args, op.to_sym, rhs)
    result.line lhs.line
    result
  end

  def new_op_asgn2 val
    recv, (call_op, _), (meth, _), (op, _), arg = val
    meth = :"#{meth}="

    result = case call_op.to_sym
             when :"."
               s(:op_asgn2, recv, meth, op.to_sym, arg)
             when :"&."
               s(:safe_op_asgn2, recv, meth, op.to_sym, arg)
             else
               raise "unknown call operator: `#{type.inspect}`"
             end

    result.line = recv.line
    result
  end

  def new_qsym_list
    s(:array).line lexer.lineno
  end

  def new_qsym_list_entry val
    _, (str, line), _ = val
    s(:lit, str.to_sym).line line
  end

  def new_qword_list
    s(:array).line lexer.lineno
  end

  def new_qword_list_entry val
    _, (str, line), _ = val
    str.force_encoding("ASCII-8BIT") unless str.valid_encoding?
    s(:str, str).line line
  end

  def new_regexp val
    (_, line), node, (options, _) = val

    node ||= s(:str, "").line line

    o, k = 0, nil
    options.split(//).uniq.each do |c| # FIX: this has a better home
      v = {
        "x" => Regexp::EXTENDED,
        "i" => Regexp::IGNORECASE,
        "m" => Regexp::MULTILINE,
        "o" => Regexp::ONCE,
        "n" => Regexp::ENC_NONE,
        "e" => Regexp::ENC_EUC,
        "s" => Regexp::ENC_SJIS,
        "u" => Regexp::ENC_UTF8,
      }[c]
      raise "unknown regexp option: #{c}" unless v
      o += v
    end

    case node.sexp_type
    when :str then
      node.sexp_type = :lit
      node[1] = if k then
                  Regexp.new(node[1], o, k)
                else
                  begin
                    Regexp.new(node[1], o)
                  rescue RegexpError => e
                    warn "WARNING: #{e.message} for #{node[1].inspect} #{options.inspect}"
                    begin
                      warn "WARNING: trying to recover with ENC_UTF8"
                      Regexp.new(node[1], Regexp::ENC_UTF8)
                    rescue RegexpError => e
                      warn "WARNING: trying to recover with ENC_NONE"
                      Regexp.new(node[1], Regexp::ENC_NONE)
                    end
                  end
                end
    when :dstr then
      if options =~ /o/ then
        node.sexp_type = :dregx_once
      else
        node.sexp_type = :dregx
      end
      node << o if o and o != 0
    else
      node = s(:dregx, "", node).line line
      node.sexp_type = :dregx_once if options =~ /o/
      node << o if o and o != 0
    end

    node
  end

  def new_resbody cond, body
    if body && body.sexp_type == :block then
      body.shift # remove block and splat it in directly
    else
      body = [body]
    end

    s(:resbody, cond, *body).line cond.line
  end

  def new_rescue body, resbody
    s(:rescue, body, resbody).line body.line
  end

  def new_sclass val
    recv, in_def, in_single, body = val[3], val[4], val[6], val[7]

    result = s(:sclass, recv)

    if body then
      if body.sexp_type == :block then
        result.push(*body.sexp_body)
      else
        result.push body
      end
    end

    result.line = val[2]
    self.in_def = in_def
    self.in_single = in_single
    result
  end

  def new_string val
    (str, line), = val

    str.force_encoding("UTF-8")
    # TODO: remove:
    str.force_encoding("ASCII-8BIT") unless str.valid_encoding?
    s(:str, str).line line
  end

  def new_super args
    if args && args.sexp_type == :block_pass then
      s(:super, args).line args.line
    else
      args ||= s(:arglist).line lexer.lineno
      s(:super, *args.sexp_body).line args.line
    end
  end

  def new_symbol val
    name = val.last
    s(:lit, name.to_sym).line lexer.lineno
  end

  def new_symbol_list
    # TODO: hunt down and try to remove ALL lexer.lineno usage!
    s(:array).line lexer.lineno
  end

  def new_symbol_list_entry val
    _, sym, _ = val

    sym ||= s(:str, "").line lexer.lineno

    case sym.sexp_type
    when :dstr then
      sym.sexp_type = :dsym
    when :str then
      sym = s(:lit, sym.last.to_sym).line sym.line
    else
      sym = s(:dsym, "", sym).line sym.line
    end

    sym
  end

  def new_undef n, m = nil
    if m then
      block_append(n, s(:undef, m).line(m.line))
    else
      s(:undef, n).line n.line
    end
  end

  def new_until block, expr, pre
    new_until_or_while :until, block, expr, pre
  end

  def new_until_or_while type, block, expr, pre
    other = type == :until ? :while : :until
    line = [block && block.line, expr.line].compact.min
    block, pre = block.last, false if block && block.sexp_type == :begin

    expr = cond expr

    result = unless expr.sexp_type == :not and canonicalize_conditions then
               s(type,  expr,      block, pre)
             else
               s(other, expr.last, block, pre)
             end

    result.line = line
    result
  end

  def new_when cond, body
    s(:when, cond, body)
  end

  def new_while block, expr, pre
    new_until_or_while :while, block, expr, pre
  end

  def new_word_list
    s(:array).line lexer.lineno
  end

  def new_word_list_entry val
    _, word, _ = val
    word.sexp_type == :evstr ? s(:dstr, "", word).line(word.line) : word
  end

  def new_xstring val
    _, node = val

    node ||= s(:str, "").line lexer.lineno

    if node then
      case node.sexp_type
      when :str
        node.sexp_type = :xstr
      when :dstr
        node.sexp_type = :dxstr
      else
        node = s(:dxstr, "", node).line node.line
      end
    end

    node
  end

  def new_yield args = nil
    # TODO: raise args.inspect unless [:arglist].include? args.first # HACK
    raise "write a test 4" if args && args.sexp_type == :block_pass
    raise SyntaxError, "Block argument should not be given." if
      args && args.sexp_type == :block_pass

    args ||= s(:arglist).line lexer.lineno

    args.sexp_type = :arglist if [:call_args, :array].include? args.sexp_type
    args = s(:arglist, args).line args.line unless args.sexp_type == :arglist

    s(:yield, *args.sexp_body).line args.line
  end

  def prev_value_to_lineno v
    s, n = v
    if String === s then
      n
    else
      lexer.lineno
    end
  end

  def next_token
    token = self.lexer.next_token

    if token and token.first != RubyLexer::EOF then
      self.last_token_type = token
      return token
    elsif !token
      return self.lexer.next_token
    else
      return [false, false]
    end
  end

  def on_error(et, ev, values)
    ev = ev.first if ev.instance_of?(Array) && ev.size == 2 && ev.last.is_a?(Integer)
    super
  rescue Racc::ParseError => e
    # I don't like how the exception obscures the error message
    e.message.replace "%s:%p :: %s" % [self.file, lexer.lineno, e.message.strip]
    warn e.message if $DEBUG
    raise
  end

  ##
  # Parse +str+ at path +file+ and return a sexp. Raises
  # Timeout::Error if it runs for more than +time+ seconds.

  def process(str, file = "(string)", time = 10)
    str.freeze

    Timeout.timeout time do
      raise "bad val: #{str.inspect}" unless String === str

      self.lexer.string = handle_encoding str

      self.file = file.dup

      @yydebug = ENV.has_key? "DEBUG"

      do_parse
    end
  end

  alias parse process

  def remove_begin node
    line = node.line

    node = node.last while node and node.sexp_type == :begin and node.size == 2

    node = s(:nil) if node == s(:begin)

    node.line ||= line

    node
  end

  alias value_expr remove_begin # TODO: for now..? could check the tree, but meh?

  def reset
    lexer.reset
    self.in_def = false
    self.in_single = 0
    self.env.reset
    self.comments.clear
    self.last_token_type = nil
  end

  def ret_args node
    if node then
      raise "write a test 5" if node.sexp_type == :block_pass

      raise SyntaxError, "block argument should not be given" if
        node.sexp_type == :block_pass

      node.sexp_type = :array if node.sexp_type == :call_args
      node = node.last if node.sexp_type == :array && node.size == 2

      # HACK matz wraps ONE of the FOUR splats in a newline to
      # distinguish. I use paren for now. ugh
      node = s(:svalue, node).line node.line if node.sexp_type == :splat and not node.paren
      node.sexp_type = :svalue if node.sexp_type == :arglist && node[1].sexp_type == :splat
    end

    node
  end

  def s(*args)
    result = Sexp.new(*args)
    # result.line ||= lexer.lineno if lexer.ss unless ENV["CHECK_LINE_NUMS"] # otherwise...
    result.file = self.file
    result
  end

  def debug n
    if ENV["PRY"] then
      require "pry"; binding.pry
    end

    raise RubyParser::SyntaxError, "debug #{n}"
  end

  def syntax_error msg
    raise RubyParser::SyntaxError, msg
  end

  alias yyerror syntax_error

  def void_stmts node
    return nil unless node
    return node unless node.sexp_type == :block

    if node.respond_to? :sexp_body= then
      node.sexp_body = node.sexp_body.map { |n| remove_begin n }
    else
      node[1..-1] = node[1..-1].map { |n| remove_begin(n) }
    end

    node
  end

  def warning s
    # do nothing for now
  end

  def whitespace_width line, remove_width = nil
    col = 0
    idx = 0

    line.chars.each do |c|
      break if remove_width && col >= remove_width
      case c
      when " " then
        col += 1
      when "\t" then
        n = TAB_WIDTH * (col / TAB_WIDTH + 1)
        break if remove_width && n > remove_width
        col = n
      else
        break
      end
      idx += 1
    end

    if remove_width then
      line[idx..-1]
    elsif line[idx] == "\n"
      nil
    else
      col
    end
  end

  alias remove_whitespace_width whitespace_width

  def wrap type, node
    value, line = node
    value = value.to_sym if value.respond_to? :to_sym
    s(type, value).line line
  end

  class Keyword
    include RubyLexer::State::Values

    class KWtable
      attr_accessor :name, :state, :id0, :id1
      def initialize(name, id=[], state=nil)
        @name  = name
        @id0, @id1 = id
        @state = state
      end
    end

    ##
    # :stopdoc:
    #
    # :expr_beg     = ignore newline, +/- is a sign.
    # :expr_end     = newline significant, +/- is an operator.
    # :expr_endarg  = ditto, and unbound braces.
    # :expr_endfn   = ditto, and unbound braces.
    # :expr_arg     = newline significant, +/- is an operator.
    # :expr_cmdarg  = ditto
    # :expr_mid     = ditto
    # :expr_fname   = ignore newline, no reserved words.
    # :expr_dot     = right after . or ::, no reserved words.
    # :expr_class   = immediate after class, no here document.
    # :expr_label   = flag bit, label is allowed.
    # :expr_labeled = flag bit, just after a label.
    # :expr_fitem   = symbol literal as FNAME.
    # :expr_value   = :expr_beg -- work to remove. Need multi-state support.

    expr_woot = EXPR_FNAME|EXPR_FITEM

    wordlist = [
                ["alias",    [:kALIAS,    :kALIAS      ], expr_woot  ],
                ["and",      [:kAND,      :kAND        ], EXPR_BEG   ],
                ["begin",    [:kBEGIN,    :kBEGIN      ], EXPR_BEG   ],
                ["break",    [:kBREAK,    :kBREAK      ], EXPR_MID   ],
                ["case",     [:kCASE,     :kCASE       ], EXPR_BEG   ],
                ["class",    [:kCLASS,    :kCLASS      ], EXPR_CLASS ],
                ["def",      [:kDEF,      :kDEF        ], EXPR_FNAME ],
                ["defined?", [:kDEFINED,  :kDEFINED    ], EXPR_ARG   ],
                ["do",       [:kDO,       :kDO         ], EXPR_BEG   ],
                ["else",     [:kELSE,     :kELSE       ], EXPR_BEG   ],
                ["elsif",    [:kELSIF,    :kELSIF      ], EXPR_BEG   ],
                ["end",      [:kEND,      :kEND        ], EXPR_END   ],
                ["ensure",   [:kENSURE,   :kENSURE     ], EXPR_BEG   ],
                ["false",    [:kFALSE,    :kFALSE      ], EXPR_END   ],
                ["for",      [:kFOR,      :kFOR        ], EXPR_BEG   ],
                ["if",       [:kIF,       :kIF_MOD     ], EXPR_BEG   ],
                ["in",       [:kIN,       :kIN         ], EXPR_BEG   ],
                ["module",   [:kMODULE,   :kMODULE     ], EXPR_BEG   ],
                ["next",     [:kNEXT,     :kNEXT       ], EXPR_MID   ],
                ["nil",      [:kNIL,      :kNIL        ], EXPR_END   ],
                ["not",      [:kNOT,      :kNOT        ], EXPR_ARG   ],
                ["or",       [:kOR,       :kOR         ], EXPR_BEG   ],
                ["redo",     [:kREDO,     :kREDO       ], EXPR_END   ],
                ["rescue",   [:kRESCUE,   :kRESCUE_MOD ], EXPR_MID   ],
                ["retry",    [:kRETRY,    :kRETRY      ], EXPR_END   ],
                ["return",   [:kRETURN,   :kRETURN     ], EXPR_MID   ],
                ["self",     [:kSELF,     :kSELF       ], EXPR_END   ],
                ["super",    [:kSUPER,    :kSUPER      ], EXPR_ARG   ],
                ["then",     [:kTHEN,     :kTHEN       ], EXPR_BEG   ],
                ["true",     [:kTRUE,     :kTRUE       ], EXPR_END   ],
                ["undef",    [:kUNDEF,    :kUNDEF      ], expr_woot  ],
                ["unless",   [:kUNLESS,   :kUNLESS_MOD ], EXPR_BEG   ],
                ["until",    [:kUNTIL,    :kUNTIL_MOD  ], EXPR_BEG   ],
                ["when",     [:kWHEN,     :kWHEN       ], EXPR_BEG   ],
                ["while",    [:kWHILE,    :kWHILE_MOD  ], EXPR_BEG   ],
                ["yield",    [:kYIELD,    :kYIELD      ], EXPR_ARG   ],
                ["BEGIN",    [:klBEGIN,   :klBEGIN     ], EXPR_END   ],
                ["END",      [:klEND,     :klEND       ], EXPR_END   ],
                ["__FILE__", [:k__FILE__, :k__FILE__   ], EXPR_END   ],
                ["__LINE__", [:k__LINE__, :k__LINE__   ], EXPR_END   ],
                ["__ENCODING__", [:k__ENCODING__, :k__ENCODING__], EXPR_END],
               ].map { |args|
      KWtable.new(*args)
    }

    # :startdoc:

    WORDLIST = Hash[*wordlist.map { |o| [o.name, o] }.flatten]

    def self.keyword str
      WORDLIST[str]
    end
  end

  class Environment
    attr_reader :env, :dyn

    def [] k
      self.all[k]
    end

    def []= k, v
      raise "no" if v == true
      self.current[k] = v
    end

    def all
      idx = @dyn.index(false) || 0
      @env[0..idx].reverse.inject { |env, scope| env.merge scope }
    end

    def current
      @env.first
    end

    def extend dyn = false
      @dyn.unshift dyn
      @env.unshift({})
    end

    def initialize dyn = false
      @dyn = []
      @env = []
      self.reset
    end

    def reset
      @dyn.clear
      @env.clear
      self.extend
    end

    def unextend
      @dyn.shift
      @env.shift
      raise "You went too far unextending env" if @env.empty?
    end
  end

  class StackState
    attr_reader :name
    attr_reader :stack
    attr_accessor :debug

    def initialize name, debug=false
      @name = name
      @stack = [false]
      @debug = debug
    end

    def inspect
      "StackState(#{@name}, #{@stack.inspect})"
    end

    def is_in_state
      log :is_in_state if debug
      @stack.last
    end

    def lexpop
      raise if @stack.size == 0
      a = @stack.pop
      b = @stack.pop
      @stack.push(a || b)
      log :lexpop if debug
    end

    def log action
      c = caller[1]
      c = caller[2] if c =~ /expr_result/
      warn "%s_stack.%s: %p at %s" % [name, action, @stack, c.clean_caller]
      nil
    end

    def pop
      r = @stack.pop
      @stack.push false if @stack.empty?
      log :pop if debug
      r
    end

    def push val
      @stack.push val
      log :push if debug
    end

    def reset
      @stack = [false]
      log :reset if debug
    end

    def restore oldstate
      @stack.replace oldstate
      log :restore if debug
    end

    def store base = false
      result = @stack.dup
      @stack.replace [base]
      log :store if debug
      result
    end
  end
end
