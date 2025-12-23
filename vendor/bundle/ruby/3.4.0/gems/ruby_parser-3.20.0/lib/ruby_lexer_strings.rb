# frozen_string_literal: true

class RubyLexer
  def eat_whitespace
    r = scan(/\s+/)
    self.lineno += r.count("\n") if r

    r += eat_whitespace if eos? && in_heredoc? # forces heredoc pop

    r
  end

  def heredoc here                              # ../compare/parse30.y:7678
    _, term, func, _indent_max, _lineno, range = here

    start_line = lineno
    eos = term # HACK
    indent = func =~ STR_FUNC_INDENT

    self.string_buffer = []

    last_line = self.ss_string[range] if range
    eol = last_line && last_line.end_with?("\r\n") ? "\r\n" : "\n" # HACK

    expand = func =~ STR_FUNC_EXPAND

    # TODO? p->heredoc_line_indent == -1

    indent_re = indent ? "[ \t]*" : nil
    eos_re    = /#{indent_re}#{Regexp.escape eos}(?=\r?\n|\z)/
    err_msg   = "can't match #{eos_re.inspect} anywhere in "

    maybe_pop_stack
    rb_compile_error err_msg if end_of_stream?

    if beginning_of_line? && scan(eos_re) then
      scan(/\r?\n|\z/)
      self.lineno += 1 if matched =~ /\n/

      heredoc_restore

      self.lex_strterm = nil
      self.lex_state = EXPR_END

      return :tSTRING_END, [term, func, range]
    end

    if expand then
      case
      when scan(/#(?=\$(-.|[a-zA-Z_0-9~\*\$\?!@\/\\;,\.=:<>\"\&\`\'+]))/) then
        # TODO: !ISASCII
        # ?! see parser_peek_variable_name
        return :tSTRING_DVAR, matched
      when scan(/#(?=\@\@?[a-zA-Z_])/) then
        # TODO: !ISASCII
        return :tSTRING_DVAR, matched
      when scan(/#[{]/) then
        self.command_start = true
        return :tSTRING_DBEG, matched
      when scan(/#/) then
        string_buffer << "#"
      end

      begin
        # NOTE: this visibly diverges from the C code but uses tokadd_string
        #       to stay clean.

        str = tokadd_string func, eol, nil
        rb_compile_error err_msg if str == RubyLexer::EOF

        if str != eol then
          str = string_buffer.join
          string_buffer.clear
          return result nil, :tSTRING_CONTENT, str, start_line
        else
          string_buffer << scan(/\r?\n/)
          self.lineno += 1 # TODO: try to remove most scan(/\n/) and friends
        end
      end until check eos_re
    else
      until check(eos_re) do
        string_buffer << scan(/.*(\r?\n|\z)/)
        self.lineno += 1
        rb_compile_error err_msg if end_of_stream?
      end
    end

    string_content = begin
                       s = string_buffer.join
                       s.b.force_encoding Encoding::UTF_8
                       s
                     end
    string_buffer.clear

    result nil, :tSTRING_CONTENT, string_content, start_line
  end

  def heredoc_identifier                        # ../compare/parse30.y:7354
    token  = :tSTRING_BEG
    func   = STR_FUNC_BORING
    term   = nil
    indent = nil
    quote  = nil
    char_pos = nil
    byte_pos = nil

    heredoc_indent_mods = "-"
    heredoc_indent_mods += '\~' if ruby23plus?

    case
    when scan(/([#{heredoc_indent_mods}]?)([\'\"\`])(.*?)\2/) then
      mods, quote, term = match[1], match[2], match[3]
      char_pos = ss.charpos
      byte_pos = ss.pos

      func |= STR_FUNC_INDENT unless mods.empty?
      func |= STR_FUNC_DEDENT if mods == "~"
      func |= case quote
              when "\'" then
                STR_SQUOTE
              when '"' then
                STR_DQUOTE
              when "`" then
                token = :tXSTRING_BEG
                STR_XQUOTE
              else
                debug 1
              end
    when scan(/[#{heredoc_indent_mods}]?([\'\"\`])(?!\1*\Z)/) then
      rb_compile_error "unterminated here document identifier"
    when scan(/([#{heredoc_indent_mods}]?)(#{IDENT_CHAR}+)/) then
      mods, term = match[1], match[2]
      quote = '"'
      char_pos = ss.charpos
      byte_pos = ss.pos

      func |= STR_FUNC_INDENT unless mods.empty?
      func |= STR_FUNC_DEDENT if mods == "~"
      func |= STR_DQUOTE
    else
      return
    end

    old_lineno = self.lineno
    rest_of_line = scan(/.*(?:\r?\n|\z)/)
    self.lineno += rest_of_line.count "\n"

    char_pos_end = ss.charpos - 1

    range = nil
    range = char_pos..char_pos_end unless rest_of_line.empty?

    self.lex_strterm = [:heredoc, term, func, indent, old_lineno, range, byte_pos]

    result nil, token, quote, old_lineno
  end

  def heredoc_restore                           # ../compare/parse30.y:7438
    _, _term, _func, _indent, lineno, range, bytepos = lex_strterm

    new_ss = ss.class.new self.ss_string[0..range.max]
    new_ss.pos = bytepos

    lineno_push lineno
    ss_push new_ss

    nil
  end

  def newtok
    string_buffer.clear
  end

  def nextc
    # TODO:
    # if (UNLIKELY((p->lex.pcur == p->lex.pend) || p->eofp || RTEST(p->lex.nextline))) {
    #     if (nextline(p)) return -1;
    # }

    maybe_pop_stack

    c = ss.getch

    if c == "\n" then
      ss.unscan
      c = nil
    end

    c
  end

  def parse_string quote                         # ../compare/parse30.y:7273
    _, func, term, paren = quote

    qwords = func =~ STR_FUNC_QWORDS
    regexp = func =~ STR_FUNC_REGEXP
    expand = func =~ STR_FUNC_EXPAND
    list   = func =~ STR_FUNC_LIST
    termx  = func =~ STR_FUNC_TERM # TODO: document wtf this means

    space = false
    term_re = regexp_cache[term]

    if termx then
      # self.nextc if qwords # delayed term

      self.lex_strterm = nil

      return result EXPR_END, regexp ? :tREGEXP_END : :tSTRING_END, term
    end

    space = true if qwords and eat_whitespace

    if list then
      debug 4
      # quote[1] -= STR_FUNC_LIST
      # space = true
    end

    # TODO: move to quote.nest!
    if string_nest == 0 && scan(term_re) then
      if qwords then
        quote[1] |= STR_FUNC_TERM

        return :tSPACE, matched
      end

      return string_term func
    end

    return result nil, :tSPACE, " " if space

    newtok

    if expand && check(/#/) then
      t = self.scan_variable_name
      return t if t

      tokadd "#"
    end

    # TODO: add string_nest, enc, base_enc ?
    lineno = self.lineno
    if tokadd_string(func, term, paren) == RubyLexer::EOF then
      if qwords then
        rb_compile_error "unterminated list meets end of file"
      end

      if regexp then
        rb_compile_error "unterminated regexp meets end of file"
      else
        rb_compile_error "unterminated string meets end of file"
      end
    end

    result nil, :tSTRING_CONTENT, string_buffer.join, lineno
  end

  # called from process_percent
  def process_percent_quote                      # ../compare/parse30.y:8645
    c = getch # type %<type><term>...<term>

    long_hand = !!(c =~ /[QqWwIixrs]/)

    if end_of_stream? || c !~ /\p{Alnum}/ then
      term = c # TODO? PERCENT_END[c] || c

      debug 2 if c && c !~ /\p{ASCII}/
      c = "Q"
    else
      term = getch

      debug 3 if term =~ /\p{Alnum}|\P{ASCII}/
    end

    if end_of_stream? or c == RubyLexer::EOF or term == RubyLexer::EOF then
      rb_compile_error "unterminated quoted string meets end of file"
    end

    # "\0" is special to indicate beg=nnd and that no nesting?
    paren = term
    term = PERCENT_END[term]
    term, paren = paren, "\0" if term.nil? # TODO: "\0" -> nil

    text = long_hand ? "%#{c}#{paren}" : "%#{term}"

    current_line = self.lineno

    token_type, string_type =
      case c
      when "Q" then
        [:tSTRING_BEG,   STR_DQUOTE]
      when "q" then
        [:tSTRING_BEG,   STR_SQUOTE]
      when "W" then
        eat_whitespace
        [:tWORDS_BEG,    STR_DQUOTE | STR_FUNC_QWORDS]
      when "w" then
        eat_whitespace
        [:tQWORDS_BEG,   STR_SQUOTE | STR_FUNC_QWORDS]
      when "I" then
        eat_whitespace
        [:tSYMBOLS_BEG,  STR_DQUOTE | STR_FUNC_QWORDS]
      when "i" then
        eat_whitespace
        [:tQSYMBOLS_BEG, STR_SQUOTE | STR_FUNC_QWORDS]
      when "x" then
        [:tXSTRING_BEG,  STR_XQUOTE]
      when "r" then
        [:tREGEXP_BEG,   STR_REGEXP]
      when "s" then
        self.lex_state = EXPR_FNAME
        [:tSYMBEG,       STR_SSYM]
      else
        rb_compile_error "unknown type of %string. Expected [QqWwIixrs], found '#{c}'."
      end

    string string_type, term, paren

    result nil, token_type, text, current_line
  end

  def process_string_or_heredoc                  # ../compare/parse30.y:9075
    if lex_strterm[0] == :heredoc then
      self.heredoc lex_strterm
    else
      self.parse_string lex_strterm
    end
  end

  def read_escape flags = nil                    # ../compare/parse30.y:6712
    case
    when scan(/\\/) then                  # Backslash
      '\\'
    when scan(/n/) then                   # newline
      "\n"
    when scan(/t/) then                   # horizontal tab
      "\t"
    when scan(/r/) then                   # carriage-return
      "\r"
    when scan(/f/) then                   # form-feed
      "\f"
    when scan(/v/) then                   # vertical tab
      "\13"
    when scan(/a/) then                   # alarm(bell)
      "\007"
    when scan(/e/) then                   # escape
      "\033"
    when scan(/[0-7]{1,3}/) then          # octal constant
      (matched.to_i(8) & 0xFF).chr.force_encoding Encoding::UTF_8
    when scan(/x([0-9a-fA-F]{1,2})/) then # hex constant
      # TODO: force encode everything to UTF-8?
      match[1].to_i(16).chr.force_encoding Encoding::UTF_8
    when scan(/b/) then                   # backspace
      "\010"
    when scan(/s/) then                   # space
      " "
    when check(/M-\\u/) then
      debug 5
    when scan(/M-\\(?=.)/) then
      c = read_escape
      c[0] = (c[0].ord | 0x80).chr
      c
    when scan(/M-(\p{ASCII})/) then
      # TODO: ISCNTRL(c) -> goto eof
      c = match[1]
      c[0] = (c[0].ord | 0x80).chr
      c
    when check(/(C-|c)\\u/) then
      debug 6
    when scan(/(C-|c)\\?\?/) then
      127.chr
    when scan(/(C-|c)\\/) then
      c = read_escape
      c[0] = (c[0].ord & 0x9f).chr
      c
    when scan(/(?:C-|c)(.)/) then
      c = match[1]
      c[0] = (c[0].ord & 0x9f).chr
      c
    when scan(/^[89]/i) then # bad octal or hex... MRI ignores them :(
      matched
    when scan(/u(\h{4})/) then
      [match[1].to_i(16)].pack("U")
    when scan(/u(\h{1,3})/) then
      debug 7
      rb_compile_error "Invalid escape character syntax"
    when scan(/u\{(\h+(?: +\h+)*)\}/) then
      match[1].split.map { |s| s.to_i(16) }.pack("U*")
    when scan(/[McCx0-9]/) || end_of_stream? then
      rb_compile_error("Invalid escape character syntax")
    else
      getch
    end.dup
  end

  def regx_options                               # ../compare/parse30.y:6914
    newtok

    options = scan(/\p{Alpha}+/) || ""

    rb_compile_error("unknown regexp options: %s" % [options]) if
      options =~ /[^ixmonesu]/

    options
  end

  def scan_variable_name                        # ../compare/parse30.y:7208
    case
    when scan(/#(?=\$(-.|[a-zA-Z_0-9~\*\$\?!@\/\\;,\.=:<>\"\&\`\'+]))/) then
      # TODO: !ISASCII
      return :tSTRING_DVAR, matched
    when scan(/#(?=\@\@?[a-zA-Z_])/) then
      # TODO: !ISASCII
      return :tSTRING_DVAR, matched
    when scan(/#[{]/) then
      self.command_start = true
      return :tSTRING_DBEG, matched
    when scan(/#/) then
      # do nothing but swallow
    end

    # if scan(/\P{ASCII}|_|\p{Alpha}/) then # TODO: fold into above DVAR cases
    #   # if (!ISASCII(c) || c == '_' || ISALPHA(c))
    #   #     return tSTRING_DVAR;
    # end

    nil
  end

  def string type, beg, nnd = nil
    # label = (IS_LABEL_POSSIBLE() ? str_label : 0);
    # p->lex.strterm = NEW_STRTERM(str_dquote | label, '"', 0);
    # p->lex.ptok = p->lex.pcur-1;

    type |= STR_FUNC_LABEL if is_label_possible?
    self.lex_strterm = [:strterm, type, beg, nnd || "\0"]
  end

  def string_term func                          # ../compare/parse30.y:7254
    self.lex_strterm = nil

    return result EXPR_END, :tREGEXP_END, self.regx_options if
      func =~ STR_FUNC_REGEXP

    if func =~ STR_FUNC_LABEL && is_label_suffix? then
      self.getch
      self.lex_state = EXPR_BEG|EXPR_LABEL

      return :tLABEL_END, string_buffer.join
    end

    self.lex_state = EXPR_END

    return :tSTRING_END, [self.matched, func]
  end

  def tokadd c                                  # ../compare/parse30.y:6548
    string_buffer << c
  end

  def tokadd_escape                              # ../compare/parse30.y:6840
    case
    when scan(/\\\n/) then
      # just ignore
    when scan(/\\([0-7]{1,3}|x[0-9a-fA-F]{1,2})/) then
      tokadd matched
    when scan(/\\([MC]-|c)(?=\\)/) then
      tokadd matched
      self.tokadd_escape
    when scan(/\\([MC]-|c)(.)/) then
      tokadd matched

      self.tokadd_escape if check(/\\/) # recurse if continued!
    when scan(/\\[McCx]/) then # all unprocessed branches from above have failed
      rb_compile_error "Invalid escape character syntax"
    when scan(/\\(.)/m) then
      chr, = match[1]

      tokadd "\\"
      tokadd chr
    else
      rb_compile_error "Invalid escape character syntax: %p" % [self.rest.lines.first]
    end
  end

  def tokadd_string func, term, paren           # ../compare/parse30.y:7020
    qwords = func =~ STR_FUNC_QWORDS
    escape = func =~ STR_FUNC_ESCAPE
    expand = func =~ STR_FUNC_EXPAND
    regexp = func =~ STR_FUNC_REGEXP

    paren_re = regexp_cache[paren] if paren != "\0"
    term_re  = if term == "\n"
                 /\r?\n/
               else
                 regexp_cache[term]
               end

    until end_of_stream? do
      case
      when paren_re && scan(paren_re) then
        self.string_nest += 1
      when scan(term_re) then
        if self.string_nest == 0 then
          self.pos -= 1 # TODO: ss.unscan 665 errors #$ HACK: why do we depend on this so hard?
          break # leave eos loop, go parse term in caller (heredoc or parse_string)
        else
          self.lineno += matched.count("\n")
          self.string_nest -= 1
        end

      when expand && check(/#[\$\@\{]/) then
        # do nothing since we used `check`
        break # leave eos loop
      when check(/\\/) then
        case
        when scan(/\\\n/) then
          self.lineno += 1
          case
          when qwords then
            tokadd "\n"
            next
          when expand then
            next if func !~ STR_FUNC_INDENT

            if term == "\n" then
              unscan     # rollback
              scan(/\\/) # and split
              scan(/\n/) # this is `matched`
              break
            end

            tokadd "\\"
            debug 9
          else
            unscan     # rollback
            scan(/\\/) # this is `matched`
          end
        when check(/\\\\/) then
          tokadd '\\' if escape
          nextc # ignore 1st \\
          nextc # for tokadd ss.matched, below
        when scan(/\\u/) then
          unless expand then
            tokadd "\\"
            next
          end

          tokadd_utf8 term, func, regexp

          next
        else
          scan(/\\/) # eat it, we know it's there

          return RubyLexer::EOF if end_of_stream?

          if scan(/\P{ASCII}/) then
            tokadd "\\" unless expand
            tokadd self.matched
            next
          end

          case
          when regexp then
            if term !~ SIMPLE_RE_META && scan(term_re) then
              tokadd matched
              next
            end

            self.pos -= 1 # TODO: ss.unscan 15 errors
            # HACK? decide whether to eat the \\ above
            if _esc = tokadd_escape && end_of_stream? then
              debug 10
            end

            next # C's continue = Ruby's next
          when expand then
            tokadd "\\" if escape
            tokadd read_escape
            next
          when qwords && scan(/\s/) then
            # ignore backslashed spaces in %w
          when !check(term_re) && !(paren_re && check(paren_re)) then
            tokadd "\\"
            next
          else
            getch # slurp it too for matched below
          end
        end # inner case for /\\/

      when scan(/\P{ASCII}/) then
        # not currently checking encoding stuff -- drops to tokadd below
      when qwords && check(/\s/) then
        break # leave eos loop
      else
        t  = Regexp.escape term == "\n" ? "\r\n" : term
        x  = Regexp.escape paren if paren && paren != "\000"
        q  = "\\s" if qwords
        re = /[^#{t}#{x}\#\\#{q}]+/

        scan re or getch
        self.lineno += matched.count "\n" if matched
      end # big case

      tokadd self.matched
    end # until end_of_stream?

    if self.matched then
      self.matched
    elsif end_of_stream? then
      RubyLexer::EOF
    end
  end # tokadd_string

  def tokadd_utf8 term, func, regexp_literal    # ../compare/parse30.y:6646
    tokadd "\\u" if regexp_literal

    case
    when scan(/\h{4}/) then
      codepoint = [matched.to_i(16)].pack("U")

      tokadd regexp_literal ? matched : codepoint
    when scan(/\{\s*(\h{1,6}(?:\s+\h{1,6})*)\s*\}/) then
      codepoints = match[1].split.map { |s| s.to_i 16 }.pack("U")

      if regexp_literal then
        tokadd "{"
        tokadd match[1].split.join(" ")
        tokadd "}"
      else
        tokadd codepoints
      end
    else
      rb_compile_error "unterminated Unicode escape"
    end
  end
end
