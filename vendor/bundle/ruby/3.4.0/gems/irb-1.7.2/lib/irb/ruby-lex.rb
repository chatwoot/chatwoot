# frozen_string_literal: false
#
#   irb/ruby-lex.rb - ruby lexcal analyzer
#   	by Keiju ISHITSUKA(keiju@ruby-lang.org)
#

require "ripper"
require "jruby" if RUBY_ENGINE == "jruby"
require_relative "nesting_parser"

# :stopdoc:
class RubyLex

  class TerminateLineInput < StandardError
    def initialize
      super("Terminate Line Input")
    end
  end

  def initialize(context)
    @context = context
    @line_no = 1
    @prompt = nil
  end

  def self.compile_with_errors_suppressed(code, line_no: 1)
    begin
      result = yield code, line_no
    rescue ArgumentError
      # Ruby can issue an error for the code if there is an
      # incomplete magic comment for encoding in it. Force an
      # expression with a new line before the code in this
      # case to prevent magic comment handling.  To make sure
      # line numbers in the lexed code remain the same,
      # decrease the line number by one.
      code = ";\n#{code}"
      line_no -= 1
      result = yield code, line_no
    end
    result
  end

  def single_line_command?(code)
    command = code.split(/\s/, 2).first
    @context.symbol_alias?(command) || @context.transform_args?(command)
  end

  # io functions
  def set_input(&block)
    @input = block
  end

  def configure_io(io)
    @io = io
    if @io.respond_to?(:check_termination)
      @io.check_termination do |code|
        if Reline::IOGate.in_pasting?
          rest = check_termination_in_prev_line(code)
          if rest
            Reline.delete_text
            rest.bytes.reverse_each do |c|
              Reline.ungetc(c)
            end
            true
          else
            false
          end
        else
          # Accept any single-line input for symbol aliases or commands that transform args
          next true if single_line_command?(code)

          _tokens, _opens, terminated = check_code_state(code)
          terminated
        end
      end
    end
    if @io.respond_to?(:dynamic_prompt)
      @io.dynamic_prompt do |lines|
        lines << '' if lines.empty?
        tokens = self.class.ripper_lex_without_warning(lines.map{ |l| l + "\n" }.join, context: @context)
        line_results = IRB::NestingParser.parse_by_line(tokens)
        tokens_until_line = []
        line_results.map.with_index do |(line_tokens, _prev_opens, next_opens, _min_depth), line_num_offset|
          line_tokens.each do |token, _s|
            # Avoid appending duplicated token. Tokens that include "\n" like multiline tstring_content can exist in multiple lines.
            tokens_until_line << token if token != tokens_until_line.last
          end
          continue = should_continue?(tokens_until_line)
          prompt(next_opens, continue, line_num_offset)
        end
      end
    end

    if @io.respond_to?(:auto_indent) and @context.auto_indent_mode
      @io.auto_indent do |lines, line_index, byte_pointer, is_newline|
        next nil if lines == [nil] # Workaround for exit IRB with CTRL+d
        next nil if !is_newline && lines[line_index]&.byteslice(0, byte_pointer)&.match?(/\A\s*\z/)

        code = lines[0..line_index].map { |l| "#{l}\n" }.join
        tokens = self.class.ripper_lex_without_warning(code, context: @context)
        process_indent_level(tokens, lines, line_index, is_newline)
      end
    end
  end

  def set_prompt(&block)
    @prompt = block
  end

  ERROR_TOKENS = [
    :on_parse_error,
    :compile_error,
    :on_assign_error,
    :on_alias_error,
    :on_class_name_error,
    :on_param_error
  ]

  def self.generate_local_variables_assign_code(local_variables)
    "#{local_variables.join('=')}=nil;" unless local_variables.empty?
  end

  # Some part of the code is not included in Ripper's token.
  # Example: DATA part, token after heredoc_beg when heredoc has unclosed embexpr.
  # With interpolated tokens, tokens.map(&:tok).join will be equal to code.
  def self.interpolate_ripper_ignored_tokens(code, tokens)
    line_positions = [0]
    code.lines.each do |line|
      line_positions << line_positions.last + line.bytesize
    end
    prev_byte_pos = 0
    interpolated = []
    prev_line = 1
    tokens.each do |t|
      line, col = t.pos
      byte_pos = line_positions[line - 1] + col
      if prev_byte_pos < byte_pos
        tok = code.byteslice(prev_byte_pos...byte_pos)
        pos = [prev_line, prev_byte_pos - line_positions[prev_line - 1]]
        interpolated << Ripper::Lexer::Elem.new(pos, :on_ignored_by_ripper, tok, 0)
        prev_line += tok.count("\n")
      end
      interpolated << t
      prev_byte_pos = byte_pos + t.tok.bytesize
      prev_line += t.tok.count("\n")
    end
    if prev_byte_pos < code.bytesize
      tok = code.byteslice(prev_byte_pos..)
      pos = [prev_line, prev_byte_pos - line_positions[prev_line - 1]]
      interpolated << Ripper::Lexer::Elem.new(pos, :on_ignored_by_ripper, tok, 0)
    end
    interpolated
  end

  def self.ripper_lex_without_warning(code, context: nil)
    verbose, $VERBOSE = $VERBOSE, nil
    lvars_code = generate_local_variables_assign_code(context&.local_variables || [])
    original_code = code
    if lvars_code
      code = "#{lvars_code}\n#{code}"
      line_no = 0
    else
      line_no = 1
    end

    compile_with_errors_suppressed(code, line_no: line_no) do |inner_code, line_no|
      lexer = Ripper::Lexer.new(inner_code, '-', line_no)
      tokens = []
      lexer.scan.each do |t|
        next if t.pos.first == 0
        prev_tk = tokens.last
        position_overlapped = prev_tk && t.pos[0] == prev_tk.pos[0] && t.pos[1] < prev_tk.pos[1] + prev_tk.tok.bytesize
        if position_overlapped
          tokens[-1] = t if ERROR_TOKENS.include?(prev_tk.event) && !ERROR_TOKENS.include?(t.event)
        else
          tokens << t
        end
      end
      interpolate_ripper_ignored_tokens(original_code, tokens)
    end
  ensure
    $VERBOSE = verbose
  end

  def prompt(opens, continue, line_num_offset)
    ltype = ltype_from_open_tokens(opens)
    indent_level = calc_indent_level(opens)
    @prompt&.call(ltype, indent_level, opens.any? || continue, @line_no + line_num_offset)
  end

  def check_code_state(code)
    check_target_code = code.gsub(/\s*\z/, '').concat("\n")
    tokens = self.class.ripper_lex_without_warning(check_target_code, context: @context)
    opens = IRB::NestingParser.open_tokens(tokens)
    [tokens, opens, code_terminated?(code, tokens, opens)]
  end

  def code_terminated?(code, tokens, opens)
    case check_code_syntax(code)
    when :unrecoverable_error
      true
    when :recoverable_error
      false
    when :other_error
      opens.empty? && !should_continue?(tokens)
    when :valid
      !should_continue?(tokens)
    end
  end

  def save_prompt_to_context_io(opens, continue, line_num_offset)
    # Implicitly saves prompt string to `@context.io.prompt`. This will be used in the next `@input.call`.
    prompt(opens, continue, line_num_offset)
  end

  def readmultiline
    save_prompt_to_context_io([], false, 0)

    # multiline
    return @input.call if @io.respond_to?(:check_termination)

    # nomultiline
    code = ''
    line_offset = 0
    loop do
      line = @input.call
      unless line
        return code.empty? ? nil : code
      end

      code << line
      # Accept any single-line input for symbol aliases or commands that transform args
      return code if single_line_command?(code)

      tokens, opens, terminated = check_code_state(code)
      return code if terminated

      line_offset += 1
      continue = should_continue?(tokens)
      save_prompt_to_context_io(opens, continue, line_offset)
    end
  end

  def each_top_level_statement
    loop do
      code = readmultiline
      break unless code

      if code != "\n"
        code.force_encoding(@io.encoding)
        yield code, @line_no
      end
      @line_no += code.count("\n")
    rescue TerminateLineInput
    end
  end

  def should_continue?(tokens)
    # Look at the last token and check if IRB need to continue reading next line.
    # Example code that should continue: `a\` `a +` `a.`
    # Trailing spaces, newline, comments are skipped
    return true if tokens.last&.event == :on_sp && tokens.last.tok == "\\\n"

    tokens.reverse_each do |token|
      case token.event
      when :on_sp, :on_nl, :on_ignored_nl, :on_comment, :on_embdoc_beg, :on_embdoc, :on_embdoc_end
        # Skip
      when :on_regexp_end, :on_heredoc_end, :on_semicolon
        # State is EXPR_BEG but should not continue
        return false
      else
        # Endless range should not continue
        return false if token.event == :on_op && token.tok.match?(/\A\.\.\.?\z/)

        # EXPR_DOT and most of the EXPR_BEG should continue
        return token.state.anybits?(Ripper::EXPR_BEG | Ripper::EXPR_DOT)
      end
    end
    false
  end

  def check_code_syntax(code)
    lvars_code = RubyLex.generate_local_variables_assign_code(@context.local_variables)
    code = "#{lvars_code}\n#{code}"

    begin # check if parser error are available
      verbose, $VERBOSE = $VERBOSE, nil
      case RUBY_ENGINE
      when 'ruby'
        self.class.compile_with_errors_suppressed(code) do |inner_code, line_no|
          RubyVM::InstructionSequence.compile(inner_code, nil, nil, line_no)
        end
      when 'jruby'
        JRuby.compile_ir(code)
      else
        catch(:valid) do
          eval("BEGIN { throw :valid, true }\n#{code}")
          false
        end
      end
    rescue EncodingError
      # This is for a hash with invalid encoding symbol, {"\xAE": 1}
      :unrecoverable_error
    rescue SyntaxError => e
      case e.message
      when /unterminated (?:string|regexp) meets end of file/
        # "unterminated regexp meets end of file"
        #
        #   example:
        #     /
        #
        # "unterminated string meets end of file"
        #
        #   example:
        #     '
        return :recoverable_error
      when /syntax error, unexpected end-of-input/
        # "syntax error, unexpected end-of-input, expecting keyword_end"
        #
        #   example:
        #     if true
        #       hoge
        #       if false
        #         fuga
        #       end
        return :recoverable_error
      when /syntax error, unexpected keyword_end/
        # "syntax error, unexpected keyword_end"
        #
        #   example:
        #     if (
        #     end
        #
        #   example:
        #     end
        return :unrecoverable_error
      when /syntax error, unexpected '\.'/
        # "syntax error, unexpected '.'"
        #
        #   example:
        #     .
        return :unrecoverable_error
      when /unexpected tREGEXP_BEG/
        # "syntax error, unexpected tREGEXP_BEG, expecting keyword_do or '{' or '('"
        #
        #   example:
        #     method / f /
        return :unrecoverable_error
      else
        return :other_error
      end
    ensure
      $VERBOSE = verbose
    end
    :valid
  end

  def calc_indent_level(opens)
    indent_level = 0
    opens.each_with_index do |t, index|
      case t.event
      when :on_heredoc_beg
        if opens[index + 1]&.event != :on_heredoc_beg
          if t.tok.match?(/^<<[~-]/)
            indent_level += 1
          else
            indent_level = 0
          end
        end
      when :on_tstring_beg, :on_regexp_beg, :on_symbeg, :on_backtick
        # can be indented if t.tok starts with `%`
      when :on_words_beg, :on_qwords_beg, :on_symbols_beg, :on_qsymbols_beg, :on_embexpr_beg
        # can be indented but not indented in current implementation
      when :on_embdoc_beg
        indent_level = 0
      else
        indent_level += 1
      end
    end
    indent_level
  end

  FREE_INDENT_TOKENS = %i[on_tstring_beg on_backtick on_regexp_beg on_symbeg]

  def free_indent_token?(token)
    FREE_INDENT_TOKENS.include?(token&.event)
  end

  # Calculates the difference of pasted code's indent and indent calculated from tokens
  def indent_difference(lines, line_results, line_index)
    loop do
      _tokens, prev_opens, _next_opens, min_depth = line_results[line_index]
      open_token = prev_opens.last
      if !open_token || (open_token.event != :on_heredoc_beg && !free_indent_token?(open_token))
        # If the leading whitespace is an indent, return the difference
        indent_level = calc_indent_level(prev_opens.take(min_depth))
        calculated_indent = 2 * indent_level
        actual_indent = lines[line_index][/^ */].size
        return actual_indent - calculated_indent
      elsif open_token.event == :on_heredoc_beg && open_token.tok.match?(/^<<[^-~]/)
        return 0
      end
      # If the leading whitespace is not an indent but part of a multiline token
      # Calculate base_indent of the multiline token's beginning line
      line_index = open_token.pos[0] - 1
    end
  end

  def process_indent_level(tokens, lines, line_index, is_newline)
    line_results = IRB::NestingParser.parse_by_line(tokens)
    result = line_results[line_index]
    if result
      _tokens, prev_opens, next_opens, min_depth = result
    else
      # When last line is empty
      prev_opens = next_opens = line_results.last[2]
      min_depth = next_opens.size
    end

    # To correctly indent line like `end.map do`, we use shortest open tokens on each line for indent calculation.
    # Shortest open tokens can be calculated by `opens.take(min_depth)`
    indent = 2 * calc_indent_level(prev_opens.take(min_depth))

    preserve_indent = lines[line_index - (is_newline ? 1 : 0)][/^ */].size

    prev_open_token = prev_opens.last
    next_open_token = next_opens.last

    # Calculates base indent for pasted code on the line where prev_open_token is located
    # irb(main):001:1*   if a # base_indent is 2, indent calculated from tokens is 0
    # irb(main):002:1*         if b # base_indent is 6, indent calculated from tokens is 2
    # irb(main):003:0>           c # base_indent is 6, indent calculated from tokens is 4
    if prev_open_token
      base_indent = [0, indent_difference(lines, line_results, prev_open_token.pos[0] - 1)].max
    else
      base_indent = 0
    end

    if free_indent_token?(prev_open_token)
      if is_newline && prev_open_token.pos[0] == line_index
        # First newline inside free-indent token
        base_indent + indent
      else
        # Accept any number of indent inside free-indent token
        preserve_indent
      end
    elsif prev_open_token&.event == :on_embdoc_beg || next_open_token&.event == :on_embdoc_beg
      if prev_open_token&.event == next_open_token&.event
        # Accept any number of indent inside embdoc content
        preserve_indent
      else
        # =begin or =end
        0
      end
    elsif prev_open_token&.event == :on_heredoc_beg
      tok = prev_open_token.tok
      if prev_opens.size <= next_opens.size
        if is_newline && lines[line_index].empty? && line_results[line_index - 1][1].last != next_open_token
          # First line in heredoc
          tok.match?(/^<<[-~]/) ? base_indent + indent : indent
        elsif tok.match?(/^<<~/)
          # Accept extra indent spaces inside `<<~` heredoc
          [base_indent + indent, preserve_indent].max
        else
          # Accept any number of indent inside other heredoc
          preserve_indent
        end
      else
        # Heredoc close
        prev_line_indent_level = calc_indent_level(prev_opens)
        tok.match?(/^<<[~-]/) ? base_indent + 2 * (prev_line_indent_level - 1) : 0
      end
    else
      base_indent + indent
    end
  end

  LTYPE_TOKENS = %i[
    on_heredoc_beg on_tstring_beg
    on_regexp_beg on_symbeg on_backtick
    on_symbols_beg on_qsymbols_beg
    on_words_beg on_qwords_beg
  ]

  def ltype_from_open_tokens(opens)
    start_token = opens.reverse_each.find do |tok|
      LTYPE_TOKENS.include?(tok.event)
    end
    return nil unless start_token

    case start_token&.event
    when :on_tstring_beg
      case start_token&.tok
      when ?"      then ?"
      when /^%.$/  then ?"
      when /^%Q.$/ then ?"
      when ?'      then ?'
      when /^%q.$/ then ?'
      end
    when :on_regexp_beg   then ?/
    when :on_symbeg       then ?:
    when :on_backtick     then ?`
    when :on_qwords_beg   then ?]
    when :on_words_beg    then ?]
    when :on_qsymbols_beg then ?]
    when :on_symbols_beg  then ?]
    when :on_heredoc_beg
      start_token&.tok =~ /<<[-~]?(['"`])\w+\1/
      $1 || ?"
    else
      nil
    end
  end

  def check_termination_in_prev_line(code)
    tokens = self.class.ripper_lex_without_warning(code, context: @context)
    past_first_newline = false
    index = tokens.rindex do |t|
      # traverse first token before last line
      if past_first_newline
        if t.tok.include?("\n")
          true
        end
      elsif t.tok.include?("\n")
        past_first_newline = true
        false
      else
        false
      end
    end

    if index
      first_token = nil
      last_line_tokens = tokens[(index + 1)..(tokens.size - 1)]
      last_line_tokens.each do |t|
        unless [:on_sp, :on_ignored_sp, :on_comment].include?(t.event)
          first_token = t
          break
        end
      end

      if first_token && first_token.state != Ripper::EXPR_DOT
        tokens_without_last_line = tokens[0..index]
        code_without_last_line = tokens_without_last_line.map(&:tok).join
        opens_without_last_line = IRB::NestingParser.open_tokens(tokens_without_last_line)
        if code_terminated?(code_without_last_line, tokens_without_last_line, opens_without_last_line)
          return last_line_tokens.map(&:tok).join
        end
      end
    end
    false
  end
end
# :startdoc:
