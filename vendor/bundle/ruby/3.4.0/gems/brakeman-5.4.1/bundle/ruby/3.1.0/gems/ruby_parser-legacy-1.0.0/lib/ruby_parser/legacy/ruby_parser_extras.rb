# encoding: ASCII-8BIT

require "sexp"
require "ruby_parser/legacy/ruby_lexer"
require "timeout"
require "rp_extensions"
require "rp_stringscanner"

module RubyParser::Legacy::RubyParserStuff
  attr_accessor :lexer, :in_def, :in_single, :file
  attr_accessor :in_kwarg
  attr_reader :env, :comments

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

  def syntax_error msg
    raise RubyParser::SyntaxError, msg
  end

  def arg_blk_pass node1, node2 # TODO: nuke
    node1 = s(:arglist, node1) unless [:arglist, :call_args, :array, :args].include? node1.sexp_type 
    node1 << node2 if node2
    node1
  end

  def arg_concat node1, node2 # TODO: nuke
    raise "huh" unless node2
    node1 << s(:splat, node2).compact
    node1
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

  def block_var *args
    result = self.args args
    result.sexp_type = :masgn
    result
  end

  def block_var18 ary, splat, block
    ary ||= s(:array)

    if splat then
      splat = splat[1] unless Symbol === splat
      ary << "*#{splat}".to_sym
    end

    ary << "&#{block[1]}".to_sym if block

    if ary.length > 2 or ary.splat then # HACK
      s(:masgn, *ary.sexp_body)
    else
      ary.last
    end
  end

  def array_to_hash array
    case array.sexp_type
    when :kwsplat then
      array
    else
      s(:hash, *array.sexp_body)
    end
  end

  def call_args args
    result = s(:call_args)

    args.each do |arg|
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
      when ",", nil then
        # ignore
      else
        raise "unhandled: #{arg.inspect} in #{args.inspect}"
      end
    end

    result
  end

  def args args
    result = s(:args)

    args.each do |arg|
      case arg
      when Sexp then
        case arg.sexp_type
        when :args, :block, :array, :call_args then # HACK call_args mismatch
          result.concat arg.sexp_body
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
      when ",", "|", ";", "(", ")", nil then
        # ignore
      else
        raise "unhandled: #{arg.inspect} in #{args.inspect}"
      end
    end

    result
  end

  def aryset receiver, index
    index ||= s()
    s(:attrasgn, receiver, :"[]=", *index.sexp_body).compact # [].sexp_body => nil
  end

  def assignable(lhs, value = nil)
    id = lhs.to_sym unless Sexp === lhs
    id = id.to_sym if Sexp === id

    raise "write a test 1" if id.to_s =~ /^(?:self|nil|true|false|__LINE__|__FILE__)$/

    raise SyntaxError, "Can't change the value of #{id}" if
      id.to_s =~ /^(?:self|nil|true|false|__LINE__|__FILE__)$/

    result = case id.to_s
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

    return result
  end

  def block_append(head, tail)
    return head if tail.nil?
    return tail if head.nil?

    line = [head.line, tail.line].compact.min

    head = remove_begin(head)
    head = s(:block, head) unless head.node_type == :block

    head.line = line
    head << tail
  end

  def cond node
    return nil if node.nil?
    node = value_expr node

    case node.sexp_type
    when :lit then
      if Regexp === node.last then
        return s(:match, node)
      else
        return node
      end
    when :and then
      return s(:and, cond(node[1]), cond(node[2]))
    when :or then
      return s(:or,  cond(node[1]), cond(node[2]))
    when :dot2 then
      label = "flip#{node.hash}"
      env[label] = :lvar
      _, lhs, rhs = node
      return s(:flip2, lhs, rhs)
    when :dot3 then
      label = "flip#{node.hash}"
      env[label] = :lvar
      _, lhs, rhs = node
      return s(:flip3, lhs, rhs)
    else
      return node
    end
  end

  ##
  # for pure ruby systems only

  def do_parse
    _racc_do_parse_rb(_racc_setup, false)
  end if ENV['PURE_RUBY']

  def new_match lhs, rhs
    if lhs then
      case lhs.sexp_type
      when :dregx, :dregx_once then
        return s(:match2, lhs, rhs).line(lhs.line)
      when :lit then
        return s(:match2, lhs, rhs).line(lhs.line) if Regexp === lhs.last
      end
    end

    if rhs then
      case rhs.sexp_type
      when :dregx, :dregx_once then
        return s(:match3, rhs, lhs).line(lhs.line)
      when :lit then
        return s(:match3, rhs, lhs).line(lhs.line) if Regexp === rhs.last
      end
    end

    return new_call(lhs, :"=~", argl(rhs)).line(lhs.line)
  end

  # TODO: remove in 4.0 or 2018-01, whichever is first
  deprecate :get_match_node, :new_match

  def gettable(id)
    lineno = id.lineno if id.respond_to? :lineno
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

    result.line lineno if lineno

    raise "identifier #{id.inspect} is not valid" unless result

    result
  end

  ##
  # Canonicalize conditionals. Eg:
  #
  #   not x ? a : b
  #
  # becomes:
  #
  #   x ? b : a

  attr_accessor :canonicalize_conditions

  def initialize(options = {})
    # no!: super()

    v = self.class.name[/1[89]/]

    self.lexer = RubyParser::Legacy::RubyLexer.new v && v.to_i
    self.lexer.parser = self
    self.in_kwarg = false

    @env = RubyParser::Legacy::RubyParserStuff::Environment.new
    @comments = []

    @canonicalize_conditions = true

    self.reset
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

    head = s(:dstr, '', head) if htype == :evstr

    case ttype
    when :str then
      if htype == :str
        head.last << tail.last
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
        tail[1] = s(:str, tail[1])
        tail.delete_at 1 if tail[1] == s(:str, '')

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

  def logical_op type, left, right
    left = value_expr left

    if left and left.sexp_type == type and not left.paren then
      node, rhs = left, nil

      loop do
        _, _lhs, rhs = node
        break unless rhs && rhs.sexp_type == type and not rhs.paren
        node = rhs
      end

      node[2] = s(type, rhs, right)

      return left
    end

    return s(type, left, right)
  end

  # TODO: remove in 4.0 or 2018-01, whichever is first
  deprecate :logop, :logical_op

  def new_aref val
    val[2] ||= s(:arglist)
    val[2].sexp_type = :arglist if val[2].sexp_type == :array # REFACTOR
    new_call val[0], :"[]", val[2]
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
      result = s(:begin, result) if result
      result = block_append(result, elsebody)
    end

    result = s(:ensure, result, ensurebody).compact if ensurebody

    result
  end

  def new_brace_body args, body, lineno
    new_iter(nil, args, body).line(lineno)
  end

  def argl x
    x = s(:arglist, x) if x and x.sexp_type == :array
    x
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

  def new_call recv, meth, args = nil, call_op = :'.'
    result = case call_op.to_sym
             when :'.'
               s(:call, recv, meth)
             when :'&.'
               s(:safe_call, recv, meth)
             else
               raise "unknown call operator: `#{type.inspect}`"
             end

    # TODO: need a test with f(&b) to produce block_pass
    # TODO: need a test with f(&b) { } to produce warning

    if args
      if [:arglist, :args, :array, :call_args].include? args.sexp_type
        result.concat args.sexp_body
      else
        result << args
      end
    end

    line = result.grep(Sexp).map(&:line).compact.min
    result.line = line if line

    result
  end

  def new_attrasgn recv, meth, call_op
    meth = :"#{meth}="

    result = case call_op.to_sym
             when :'.'
               s(:attrasgn, recv, meth)
             when :'&.'
               s(:safe_attrasgn, recv, meth)
             else
               raise "unknown call operator: `#{type.inspect}`"
             end

    result.line = recv.line
    result
  end

  def new_case expr, body, line
    result = s(:case, expr)

    while body and body.node_type == :when
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
    line, path, superclass, body = val[1], val[2], val[3], val[5]

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

  def new_defn val
    (_, line), (name, _), _, args, body, * = val
    body ||= s(:nil)

    result = s(:defn, name.to_sym, args)

    if body then
      if body.sexp_type == :block then
        result.push(*body.sexp_body)
      else
        result.push body
      end
    end

    args.line line
    result.line = line
    result.comments = self.comments.pop

    result
  end

  def new_defs val
    recv, (name, _line), args, body = val[1], val[4], val[6], val[7]
    body ||= s(:nil)

    result = s(:defs, recv, name.to_sym, args)

    if body then
      if body.sexp_type == :block then
        result.push(*body.sexp_body)
      else
        result.push body
      end
    end

    result.line = recv.line
    result.comments = self.comments.pop
    result
  end

  def new_do_body args, body, lineno
    new_iter(nil, args, body).line(lineno)
  end

  def new_for expr, var, body
    result = s(:for, expr, var).line(var.line)
    result << body if body
    result
  end

  def new_hash val
    s(:hash, *val[2].values).line(val[1])
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

    args.sexp_type = :args unless args == 0

    result
  end

  def new_masgn_arg rhs, wrap = false
    rhs = value_expr(rhs)
    rhs = s(:to_ary, rhs) if wrap # HACK: could be array if lhs isn't right
    rhs
  end

  def new_masgn lhs, rhs, wrap = false
    _, ary = lhs

    rhs = value_expr(rhs)
    rhs = ary ? s(:to_ary, rhs) : s(:array, rhs) if wrap

    lhs.delete_at 1 if ary.nil?
    lhs << rhs

    lhs
  end

  def new_module val
    line, path, body = val[1], val[2], val[4]

    result = s(:module, path)

    if body then # REFACTOR?
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

  def new_op_asgn val
    lhs, asgn_op, arg = val[0], val[1].to_sym, val[2]
    name = lhs.value
    arg = remove_begin(arg)
    result = case asgn_op # REFACTOR
             when :"||" then
               lhs << arg
               s(:op_asgn_or, self.gettable(name), lhs)
             when :"&&" then
               lhs << arg
               s(:op_asgn_and, self.gettable(name), lhs)
             else
               # TODO: why [2] ?
               lhs[2] = new_call(self.gettable(name), asgn_op, argl(arg))
               lhs
             end
    result.line = lhs.line
    result
  end

  def new_op_asgn2 val
    recv, call_op, meth, op, arg = val
    meth = :"#{meth}="

    result = case call_op.to_sym
             when :'.'
               s(:op_asgn2, recv, meth, op.to_sym, arg)
             when :'&.'
               s(:safe_op_asgn2, recv, meth, op.to_sym, arg)
             else
               raise "unknown call operator: `#{type.inspect}`"
             end

    result.line = recv.line
    result
  end

  def new_regexp val
    node = val[1] || s(:str, '')
    options = val[2]

    o, k = 0, nil
    options.split(//).uniq.each do |c| # FIX: this has a better home
      v = {
        'x' => Regexp::EXTENDED,
        'i' => Regexp::IGNORECASE,
        'm' => Regexp::MULTILINE,
        'o' => Regexp::ONCE,
        'n' => Regexp::ENC_NONE,
        'e' => Regexp::ENC_EUC,
        's' => Regexp::ENC_SJIS,
        'u' => Regexp::ENC_UTF8,
      }[c]
      raise "unknown regexp option: #{c}" unless v
      o += v

      # encoding options are ignored on 1.9+
      k = c if c =~ /[esu]/ if RUBY_VERSION < "1.9"
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
                    warn "WA\RNING: #{e.message} for #{node[1].inspect} #{options.inspect}"
                    begin
                      warn "WA\RNING: trying to recover with ENC_UTF8"
                      Regexp.new(node[1], Regexp::ENC_UTF8)
                    rescue RegexpError => e
                      warn "WA\RNING: trying to recover with ENC_NONE"
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
      node = s(:dregx, '', node);
      node.sexp_type = :dregx_once if options =~ /o/
      node << o if o and o != 0
    end

    node
  end

  def new_rescue body, resbody
    s(:rescue, body, resbody)
  end

  def new_resbody cond, body
    if body && body.sexp_type == :block then
      body.shift # remove block and splat it in directly
    else
      body = [body]
    end
    s(:resbody, cond, *body).line cond.line
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
    str = val[0]
    str.force_encoding("ASCII-8BIT") unless str.valid_encoding? unless RUBY_VERSION < "1.9"
    result = s(:str, str)
    self.lexer.fixup_lineno str.count("\n")
    result
  end

  def new_qword_list_entry val
    str = val[1]
    str.force_encoding("ASCII-8BIT") unless str.valid_encoding? unless RUBY_VERSION < "1.9"
    result = s(:str, str)
    self.lexer.fixup_lineno
    result
  end

  def new_qword_list
    result = s(:array)
    self.lexer.fixup_lineno
    result
  end

  def new_word_list
    result = s(:array)
    self.lexer.fixup_lineno
    result
  end

  def new_word_list_entry val
    result = val[1].sexp_type == :evstr ? s(:dstr, "", val[1]) : val[1]
    self.lexer.fixup_lineno
    result
  end

  def new_qsym_list
    result = s(:array)
    self.lexer.fixup_lineno
    result
  end

  def new_qsym_list_entry val
    result = s(:lit, val[1].to_sym)
    self.lexer.fixup_lineno
    result
  end

  def new_symbol_list
    result = s(:array)
    self.lexer.fixup_lineno
    result
  end

  def new_symbol_list_entry val
    _list, sym, _nil = val # TODO: use _list
    result = val[1]

    result ||= s(:str, "")

    case sym.sexp_type
    when :dstr then
      sym.sexp_type = :dsym
    when :str then
      sym = s(:lit, sym.last.to_sym)
    else
      sym = s(:dsym, "", sym || s(:str, ""))
    end
    self.lexer.fixup_lineno
    sym
  end

  def new_super args
    if args && args.node_type == :block_pass then
      s(:super, args)
    else
      args ||= s(:arglist)
      s(:super, *args.sexp_body)
    end
  end

  def new_undef n, m = nil
    if m then
      block_append(n, s(:undef, m))
    else
      s(:undef, n)
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

  def new_xstring str
    if str then
      case str.sexp_type
      when :str
        str.sexp_type = :xstr
      when :dstr
        str.sexp_type = :dxstr
      else
        str = s(:dxstr, '', str)
      end
      str
    else
      s(:xstr, '')
    end
  end

  def new_yield args = nil
    # TODO: raise args.inspect unless [:arglist].include? args.first # HACK
    raise "write a test 4" if args && args.node_type == :block_pass
    raise SyntaxError, "Block argument should not be given." if
      args && args.node_type == :block_pass

    args ||= s(:arglist)

    args.sexp_type = :arglist if [:call_args, :array].include? args.sexp_type
    args = s(:arglist, args) unless args.sexp_type == :arglist

    return s(:yield, *args.sexp_body)
  end

  def next_token
    token = self.lexer.next_token

    if token and token.first != RubyLexer::EOF then
      return token
    else
      return [false, '$end']
    end
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

  # TODO: remove in 4.0 or 2018-01, whichever is first
  deprecate :node_assign, :new_assign

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
    encoding, str = "utf-8", str[3..-1] if first =~ /\A\xEF\xBB\xBF/

    encoding = $1.strip if header.find { |s|
      s[/^#.*?-\*-.*?coding:\s*([^ ;]+).*?-\*-/, 1] ||
      s[/^#.*(?:en)?coding(?:\s*[:=])\s*([\w-]+)/, 1]
    }

    if encoding then
      if has_enc then
        encoding.sub!(/utf-8-.+$/, 'utf-8') # HACK for stupid emacs formats
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
  # Parse +str+ at path +file+ and return a sexp. Raises
  # Timeout::Error if it runs for more than +time+ seconds.

  def process(str, file = "(string)", time = 10)
    Timeout.timeout time do
      raise "bad val: #{str.inspect}" unless String === str

      str = handle_encoding str

      self.file = file.dup

      @yydebug = ENV.has_key? 'DEBUG'

      # HACK -- need to get tests passing more than have graceful code
      self.lexer.ss = RPStringScanner.new str

      do_parse
    end
  end

  alias :parse :process

  def remove_begin node
    oldnode = node
    if node and node.sexp_type == :begin and node.size == 2 then
      node = node.last
      node.line = oldnode.line
    end
    node
  end

  def reset
    lexer.reset
    self.in_def = false
    self.in_single = 0
    self.env.reset
    self.comments.clear
  end

  def block_dup_check call_or_args, block
    syntax_error "Both block arg and actual block given." if
      block and call_or_args.block_pass?
  end

  def inverted? val
    [:return, :next, :break, :yield].include? val[0].sexp_type
  end

  def invert_block_call val
    (type, call), iter = val

    iter.insert 1, call

    [iter, s(type)]
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
      node = s(:svalue, node) if node.sexp_type == :splat and not node.paren
      node.sexp_type = :svalue if node.sexp_type == :arglist && node[1].sexp_type == :splat
    end

    node
  end

  def s(*args)
    result = Sexp.new(*args)
    result.line ||= lexer.lineno if lexer.ss          # otherwise...
    result.file = self.file
    result
  end

  def value_expr oldnode # HACK: much more to do
    node = remove_begin oldnode
    node.line = oldnode.line if oldnode
    node[2] = value_expr node[2] if node and node.sexp_type == :if
    node
  end

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

  alias yyerror syntax_error

  class Keyword
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
    # :expr_beg    = ignore newline, +/- is a sign.
    # :expr_end    = newline significant, +/- is a operator.
    # :expr_arg    = newline significant, +/- is a operator.
    # :expr_cmdarg = newline significant, +/- is a operator.
    # :expr_endarg = newline significant, +/- is a operator.
    # :expr_mid    = newline significant, +/- is a operator.
    # :expr_fname  = ignore newline, no reserved words.
    # :expr_dot    = right after . or ::, no reserved words.
    # :expr_class  = immediate after class, no here document.

    wordlist = [
                ["end",      [:kEND,      :kEND        ], :expr_end   ],
                ["else",     [:kELSE,     :kELSE       ], :expr_beg   ],
                ["case",     [:kCASE,     :kCASE       ], :expr_beg   ],
                ["ensure",   [:kENSURE,   :kENSURE     ], :expr_beg   ],
                ["module",   [:kMODULE,   :kMODULE     ], :expr_beg   ],
                ["elsif",    [:kELSIF,    :kELSIF      ], :expr_beg   ],
                ["def",      [:kDEF,      :kDEF        ], :expr_fname ],
                ["rescue",   [:kRESCUE,   :kRESCUE_MOD ], :expr_mid   ],
                ["not",      [:kNOT,      :kNOT        ], :expr_beg   ],
                ["then",     [:kTHEN,     :kTHEN       ], :expr_beg   ],
                ["yield",    [:kYIELD,    :kYIELD      ], :expr_arg   ],
                ["for",      [:kFOR,      :kFOR        ], :expr_beg   ],
                ["self",     [:kSELF,     :kSELF       ], :expr_end   ],
                ["false",    [:kFALSE,    :kFALSE      ], :expr_end   ],
                ["retry",    [:kRETRY,    :kRETRY      ], :expr_end   ],
                ["return",   [:kRETURN,   :kRETURN     ], :expr_mid   ],
                ["true",     [:kTRUE,     :kTRUE       ], :expr_end   ],
                ["if",       [:kIF,       :kIF_MOD     ], :expr_beg   ],
                ["defined?", [:kDEFINED,  :kDEFINED    ], :expr_arg   ],
                ["super",    [:kSUPER,    :kSUPER      ], :expr_arg   ],
                ["undef",    [:kUNDEF,    :kUNDEF      ], :expr_fname ],
                ["break",    [:kBREAK,    :kBREAK      ], :expr_mid   ],
                ["in",       [:kIN,       :kIN         ], :expr_beg   ],
                ["do",       [:kDO,       :kDO         ], :expr_beg   ],
                ["nil",      [:kNIL,      :kNIL        ], :expr_end   ],
                ["until",    [:kUNTIL,    :kUNTIL_MOD  ], :expr_beg   ],
                ["unless",   [:kUNLESS,   :kUNLESS_MOD ], :expr_beg   ],
                ["or",       [:kOR,       :kOR         ], :expr_beg   ],
                ["next",     [:kNEXT,     :kNEXT       ], :expr_mid   ],
                ["when",     [:kWHEN,     :kWHEN       ], :expr_beg   ],
                ["redo",     [:kREDO,     :kREDO       ], :expr_end   ],
                ["and",      [:kAND,      :kAND        ], :expr_beg   ],
                ["begin",    [:kBEGIN,    :kBEGIN      ], :expr_beg   ],
                ["__LINE__", [:k__LINE__, :k__LINE__   ], :expr_end   ],
                ["class",    [:kCLASS,    :kCLASS      ], :expr_class ],
                ["__FILE__", [:k__FILE__, :k__FILE__   ], :expr_end   ],
                ["END",      [:klEND,     :klEND       ], :expr_end   ],
                ["BEGIN",    [:klBEGIN,   :klBEGIN     ], :expr_end   ],
                ["while",    [:kWHILE,    :kWHILE_MOD  ], :expr_beg   ],
                ["alias",    [:kALIAS,    :kALIAS      ], :expr_fname ],
                ["__ENCODING__", [:k__ENCODING__, :k__ENCODING__], :expr_end],
               ].map { |args| KWtable.new(*args) }

    # :startdoc:

    WORDLIST18 = Hash[*wordlist.map { |o| [o.name, o] }.flatten]
    WORDLIST19 = Hash[*wordlist.map { |o| [o.name, o] }.flatten]

    WORDLIST18.delete "__ENCODING__"

    %w[and case elsif for if in module or unless until when while].each do |k|
      WORDLIST19[k] = WORDLIST19[k].dup
      WORDLIST19[k].state = :expr_value
    end
    %w[not].each do |k|
      WORDLIST19[k] = WORDLIST19[k].dup
      WORDLIST19[k].state = :expr_arg
    end

    def self.keyword18 str # REFACTOR
      WORDLIST18[str]
    end

    def self.keyword19 str
      WORDLIST19[str]
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

    def reset
      @stack = [false]
      log :reset if debug
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

    def store base = false
      result = @stack.dup
      @stack.replace [base]
      log :store if debug
      result
    end

    def restore oldstate
      @stack.replace oldstate
      log :restore if debug
    end
  end
end
