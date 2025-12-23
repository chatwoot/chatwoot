%%{
  machine re_scanner;
  include re_char_type "char_type.rl";
  include re_property  "property.rl";

  utf8_2_byte           = (0xc2..0xdf 0x80..0xbf);
  utf8_3_byte           = (0xe0..0xef 0x80..0xbf 0x80..0xbf);
  utf8_4_byte           = (0xf0..0xf4 0x80..0xbf 0x80..0xbf 0x80..0xbf);
  utf8_multibyte        = utf8_2_byte | utf8_3_byte | utf8_4_byte;

  dot                   = '.';
  backslash             = '\\';
  alternation           = '|';
  beginning_of_line     = '^';
  end_of_line           = '$';

  range_open            = '{';
  range_close           = '}';
  curlies               = range_open | range_close;

  group_open            = '(';
  group_close           = ')';
  parentheses           = group_open | group_close;

  set_open              = '[';
  set_close             = ']';
  brackets              = set_open | set_close;

  comment               = ('#' . [^\n]* . '\n'?);

  class_posix           = ('[:' . '^'? . [^\[\]]* . ':]');

  line_anchor           = beginning_of_line | end_of_line;
  anchor_char           = [AbBzZG];

  escaped_ascii         = [abefnrtv];
  octal_sequence        = [0-7]{1,3};

  hex_sequence          = 'x' . xdigit{1,2};
  hex_sequence_err      = 'x' . [^0-9a-fA-F{];

  codepoint_single      = 'u' . xdigit{4};
  codepoint_list        = 'u{' . xdigit{1,6} . (space . xdigit{1,6})* . '}';
  codepoint_sequence    = codepoint_single | codepoint_list;

  control_sequence      = ('c' | 'C-') . (backslash . 'M-')? . backslash? . any;

  meta_sequence         = 'M-' . (backslash . ('c' | 'C-'))? . backslash? . any;

  sequence_char         = [CMcux];

  zero_or_one           = '?' | '??' | '?+';
  zero_or_more          = '*' | '*?' | '*+';
  one_or_more           = '+' | '+?' | '++';

  quantifier_greedy     = '?'  | '*'  | '+';

  quantity_exact        = (digit+);
  quantity_minimum      = (digit+) . ',';
  quantity_maximum      = ',' . (digit+);
  quantity_range        = (digit+) . ',' . (digit+);
  quantifier_interval   = range_open . ( quantity_exact | quantity_minimum |
                          quantity_maximum | quantity_range ) . range_close;

  conditional           = '(?(';

  group_comment         = '?#' . [^)]* . group_close;

  group_atomic          = '?>';
  group_passive         = '?:';
  group_absence         = '?~';

  assertion_lookahead   = '?=';
  assertion_nlookahead  = '?!';
  assertion_lookbehind  = '?<=';
  assertion_nlookbehind = '?<!';

  # try to treat every other group head as options group, like Ruby
  group_options         = '?' . ( [^!#'():<=>~]+ . ':'? ) ?;

  group_name_id_ab      = ([^!=0-9\->] | utf8_multibyte) . ([^>] | utf8_multibyte)*;
  group_name_id_sq      = ([^0-9\-']   | utf8_multibyte) . ([^'] | utf8_multibyte)*;
  group_number          = '-'? . [0-9]+;
  group_level           = [+\-] . [0-9]+;

  group_name            = ('<' . group_name_id_ab? . '>') |
                          ("'" . group_name_id_sq? . "'");
  group_lookup          = group_name | group_number;

  group_named           = ('?' . group_name );

  group_ref_body        = (('<' . (group_name_id_ab? | group_number) . group_level? '>') |
                           ("'" . (group_name_id_sq? | group_number) . group_level? "'"));

  group_ref             = 'k' . group_ref_body;
  group_call            = 'g' . group_ref_body;

  group_type            = group_atomic | group_passive | group_absence | group_named;

  keep_mark             = 'K';

  assertion_type        = assertion_lookahead  | assertion_nlookahead |
                          assertion_lookbehind | assertion_nlookbehind;

  # characters that 'break' a literal
  meta_char             = dot | backslash | alternation |
                          curlies | parentheses | brackets |
                          line_anchor | quantifier_greedy;

  literal_delimiters    = ']' | '}';

  ascii_print           = ((0x20..0x7e) - meta_char - '#');
  ascii_nonprint        = (0x01..0x1f | 0x7f);

  non_literal_escape    = char_type_char | anchor_char | escaped_ascii |
                          keep_mark | sequence_char;

  # escapes that also work within a character set
  set_escape            = backslash | brackets | escaped_ascii |
                          octal_sequence | property_char |
                          sequence_char | single_codepoint_char_type;


  # EOF error, used where it can be detected
  action premature_end_error {
    text = copy(data, ts ? ts-1 : 0, -1)
    raise PrematureEndError.new(text)
  }

  # Invalid sequence error, used from sequences, like escapes and sets
  action invalid_sequence_error {
    text = copy(data, ts ? ts-1 : 0, -1)
    raise ValidationError.for(:sequence, 'sequence', text)
  }

  # group (nesting) and set open/close actions
  action group_opened { self.group_depth = group_depth + 1 }
  action group_closed { self.group_depth = group_depth - 1 }
  action set_opened   { self.set_depth   = set_depth   + 1 }
  action set_closed   { self.set_depth   = set_depth   - 1 }

  # Character set scanner, continues consuming characters until it meets the
  # closing bracket of the set.
  # --------------------------------------------------------------------------
  character_set := |*
    set_close > (set_meta, 2) @set_closed {
      emit(:set, :close, copy(data, ts, te))
      if in_set?
        fret;
      else
        fgoto main;
      end
    };

    '-]' @set_closed { # special case, emits two tokens
      emit(:literal, :literal, '-')
      emit(:set, :close, ']')
      if in_set?
        fret;
      else
        fgoto main;
      end
    };

    '-&&' { # special case, emits two tokens
      emit(:literal, :literal, '-')
      emit(:set, :intersection, '&&')
    };

    '^' {
      if prev_token[1] == :open
        emit(:set, :negate, '^')
      else
        emit(:literal, :literal, '^')
      end
    };

    '-' {
      # ranges cant start with the opening bracket, a subset, or
      # intersection/negation/range operators
      if prev_token[0] == :set
        emit(:literal, :literal, '-')
      else
        emit(:set, :range, '-')
      end
    };

    # Unlike ranges, intersections can start or end at set boundaries, whereupon
    # they match nothing: r = /[a&&]/; [r =~ ?a, r =~ ?&] # => [nil, nil]
    '&&' {
      emit(:set, :intersection, '&&')
    };

    backslash {
      fcall set_escape_sequence;
    };

    set_open >(open_bracket, 1) >set_opened {
      emit(:set, :open, '[')
      fcall character_set;
    };

    class_posix >(open_bracket, 1) @set_closed @eof(premature_end_error) {
      text = copy(data, ts, te)

      type = :posixclass
      class_name = text[2..-3]
      if class_name[0] == '^'
        class_name = class_name[1..-1]
        type = :nonposixclass
      end

      unless self.class.posix_classes.include?(class_name)
        raise ValidationError.for(:posix_class, text)
      end

      emit(type, class_name.to_sym, text)
    };

    meta_char > (set_meta, 1) {
      emit(:literal, :literal, copy(data, ts, te))
    };

    any | ascii_nonprint | utf8_multibyte {
      text = copy(data, ts, te)
      emit(:literal, :literal, text)
    };
  *|;

  # set escapes scanner
  # --------------------------------------------------------------------------
  set_escape_sequence := |*
    # Special case: in sets, octal sequences have higher priority than backrefs
    octal_sequence {
      emit(:escape, :octal, copy(data, ts-1, te))
      fret;
    };

    # Scan all other escapes that work in sets with the generic escape scanner
    set_escape > (escaped_set_alpha, 2) {
      fhold;
      fnext character_set;
      fcall escape_sequence;
    };

    # Treat all remaining escapes - those not supported in sets - as literal.
    # (This currently includes \^, \-, \&, \:, although these could potentially
    # be meta chars when not escaped, depending on their position in the set.)
    any > (escaped_set_alpha, 1) {
      emit(:escape, :literal, copy(data, ts-1, te))
      fret;
    };
  *|;


  # escape sequence scanner
  # --------------------------------------------------------------------------
  escape_sequence := |*
    [1-9] {
      text = copy(data, ts-1, te)
      emit(:backref, :number, text)
      fret;
    };

    octal_sequence {
      emit(:escape, :octal, copy(data, ts-1, te))
      fret;
    };

    [8-9] . [0-9] { # special case, emits two tokens
      text = copy(data, ts-1, te)
      emit(:escape, :literal, text[0, 2])
      emit(:literal, :literal, text[2])
      fret;
    };

    meta_char {
      case text = copy(data, ts-1, te)
      when '\.';  emit(:escape, :dot,               text)
      when '\|';  emit(:escape, :alternation,       text)
      when '\^';  emit(:escape, :bol,               text)
      when '\$';  emit(:escape, :eol,               text)
      when '\?';  emit(:escape, :zero_or_one,       text)
      when '\*';  emit(:escape, :zero_or_more,      text)
      when '\+';  emit(:escape, :one_or_more,       text)
      when '\(';  emit(:escape, :group_open,        text)
      when '\)';  emit(:escape, :group_close,       text)
      when '\{';  emit(:escape, :interval_open,     text)
      when '\}';  emit(:escape, :interval_close,    text)
      when '\[';  emit(:escape, :set_open,          text)
      when '\]';  emit(:escape, :set_close,         text)
      when "\\\\";
        emit(:escape, :backslash, text)
      end
      fret;
    };

    escaped_ascii > (escaped_alpha, 7) {
      # \b is emitted as backspace only when inside a character set, otherwise
      # it is a word boundary anchor. A syntax might "normalize" it if needed.
      case text = copy(data, ts-1, te)
      when '\a'; emit(:escape, :bell,           text)
      when '\b'; emit(:escape, :backspace,      text)
      when '\e'; emit(:escape, :escape,         text)
      when '\f'; emit(:escape, :form_feed,      text)
      when '\n'; emit(:escape, :newline,        text)
      when '\r'; emit(:escape, :carriage,       text)
      when '\t'; emit(:escape, :tab,            text)
      when '\v'; emit(:escape, :vertical_tab,   text)
      end
      fret;
    };

    codepoint_sequence > (escaped_alpha, 6) $eof(premature_end_error) {
      text = copy(data, ts-1, te)
      if text[2] == '{'
        emit(:escape, :codepoint_list, text)
      else
        emit(:escape, :codepoint,      text)
      end
      fret;
    };

    hex_sequence > (escaped_alpha, 5) @eof(premature_end_error) {
      emit(:escape, :hex, copy(data, ts-1, te))
      fret;
    };

    hex_sequence_err @invalid_sequence_error {
      fret;
    };

    control_sequence >(escaped_alpha, 4) $eof(premature_end_error) {
      emit_meta_control_sequence(data, ts, te, :control)
      fret;
    };

    meta_sequence >(backslashed, 3) $eof(premature_end_error) {
      emit_meta_control_sequence(data, ts, te, :meta_sequence)
      fret;
    };

    char_type_char > (escaped_alpha, 2) {
      fhold;
      fnext *(in_set? ? fentry(character_set) : fentry(main));
      fcall char_type;
    };

    property_char > (escaped_alpha, 2) {
      fhold;
      fnext *(in_set? ? fentry(character_set) : fentry(main));
      fcall unicode_property;
    };

    (any -- non_literal_escape) | utf8_multibyte > (escaped_alpha, 1) {
      emit(:escape, :literal, copy(data, ts-1, te))
      fret;
    };
  *|;


  # conditional expressions scanner
  # --------------------------------------------------------------------------
  conditional_expression := |*
    group_lookup . ')' {
      text = copy(data, ts, te-1)
      text =~ /[^0]/ or raise ValidationError.for(:backref, 'condition', 'invalid ref ID')
      emit(:conditional, :condition, text)
      emit(:conditional, :condition_close, ')')
    };

    any {
      fhold;
      fcall main;
    };
  *|;


  # Main scanner
  # --------------------------------------------------------------------------
  main := |*

    # Meta characters
    # ------------------------------------------------------------------------
    dot {
      emit(:meta, :dot, copy(data, ts, te))
    };

    alternation {
      if conditional_stack.last == group_depth
        emit(:conditional, :separator, copy(data, ts, te))
      else
        emit(:meta, :alternation, copy(data, ts, te))
      end
    };

    # Anchors
    # ------------------------------------------------------------------------
    beginning_of_line {
      emit(:anchor, :bol, copy(data, ts, te))
    };

    end_of_line {
      emit(:anchor, :eol, copy(data, ts, te))
    };

    backslash . keep_mark > (backslashed, 4) {
      emit(:keep, :mark, copy(data, ts, te))
    };

    backslash . anchor_char > (backslashed, 3) {
      case text = copy(data, ts, te)
      when '\A';  emit(:anchor, :bos,                text)
      when '\z';  emit(:anchor, :eos,                text)
      when '\Z';  emit(:anchor, :eos_ob_eol,         text)
      when '\b';  emit(:anchor, :word_boundary,      text)
      when '\B';  emit(:anchor, :nonword_boundary,   text)
      when '\G';  emit(:anchor, :match_start,        text)
      end
    };

    literal_delimiters {
      append_literal(data, ts, te)
    };

    # Character sets
    # ------------------------------------------------------------------------
    set_open >set_opened {
      emit(:set, :open, copy(data, ts, te))
      fcall character_set;
    };


    # Conditional expression
    #   (?(condition)Y|N)   conditional expression
    # ------------------------------------------------------------------------
    conditional {
      text = copy(data, ts, te)

      conditional_stack << group_depth

      emit(:conditional, :open, text[0..-2])
      emit(:conditional, :condition_open, '(')
      fcall conditional_expression;
    };


    # (?#...) comments: parsed as a single expression, without introducing a
    # new nesting level. Comments may not include parentheses, escaped or not.
    # special case for close to get the correct closing count.
    # ------------------------------------------------------------------------
    (group_open . group_comment) @group_closed {
      emit(:group, :comment, copy(data, ts, te))
    };

    # Expression options:
    #   (?imxdau-imx)         option on/off
    #                         i: ignore case
    #                         m: multi-line (dot(.) match newline)
    #                         x: extended form
    #                         d: default class rules (1.9 compatible)
    #                         a: ASCII class rules (\s, \w, etc.)
    #                         u: Unicode class rules (\s, \w, etc.)
    #
    #   (?imxdau-imx:subexp)  option on/off for subexp
    # ------------------------------------------------------------------------
    (group_open . group_options) >group_opened {
      text = copy(data, ts, te)
      if text[2..-1] =~ /([^\-mixdau:]|^$)|-.*([dau])/
        raise ValidationError.for(:group_option, $1 || "-#{$2}", text)
      end
      emit_options(text)
    };

    # Assertions
    #   (?=subexp)          look-ahead
    #   (?!subexp)          negative look-ahead
    #   (?<=subexp)         look-behind
    #   (?<!subexp)         negative look-behind
    # ------------------------------------------------------------------------
    (group_open . assertion_type) >group_opened {
      case text = copy(data, ts, te)
      when '(?=';  emit(:assertion, :lookahead,    text)
      when '(?!';  emit(:assertion, :nlookahead,   text)
      when '(?<='; emit(:assertion, :lookbehind,   text)
      when '(?<!'; emit(:assertion, :nlookbehind,  text)
      end
    };

    # Groups
    #   (?:subexp)          passive (non-captured) group
    #   (?>subexp)          atomic group, don't backtrack in subexp.
    #   (?~subexp)          absence group, matches anything that is not subexp
    #   (?<name>subexp)     named group
    #   (?'name'subexp)     named group (single quoted version)
    #   (subexp)            captured group
    # ------------------------------------------------------------------------
    (group_open . group_type) >group_opened {
      case text = copy(data, ts, te)
      when '(?:';  emit(:group, :passive,      text)
      when '(?>';  emit(:group, :atomic,       text)
      when '(?~';  emit(:group, :absence,      text)

      when /^\(\?(?:<>|'')/
        raise ValidationError.for(:group, 'named group', 'name is empty')

      when /^\(\?<[^>]+>/
        emit(:group, :named_ab,  text)

      when /^\(\?'[^']+'/
        emit(:group, :named_sq,  text)

      end
    };

    group_open @group_opened {
      text = copy(data, ts, te)
      emit(:group, :capture, text)
    };

    group_close @group_closed {
      if conditional_stack.last == group_depth + 1
        conditional_stack.pop
        emit(:conditional, :close, ')')
      elsif group_depth >= 0
        if spacing_stack.length > 1 &&
           spacing_stack.last[:depth] == group_depth + 1
          spacing_stack.pop
          self.free_spacing = spacing_stack.last[:free_spacing]
        end

        emit(:group, :close, ')')
      else
        raise ValidationError.for(:group, 'group', 'unmatched close parenthesis')
      end
    };


    # Group backreference, named and numbered
    # ------------------------------------------------------------------------
    backslash . (group_ref) > (backslashed, 4) {
      case text = copy(data, ts, te)
      when /^\\k(.)[^0-9\-][^+\-]*['>]$/
        emit(:backref, $1 == '<' ? :name_ref_ab : :name_ref_sq, text)
      when /^\\k(.)0*[1-9]\d*['>]$/
        emit(:backref, $1 == '<' ? :number_ref_ab : :number_ref_sq, text)
      when /^\\k(.)-0*[1-9]\d*['>]$/
        emit(:backref, $1 == '<' ? :number_rel_ref_ab : :number_rel_ref_sq, text)
      when /^\\k(.)[^0-9\-].*[+\-]\d+['>]$/
        emit(:backref, $1 == '<' ? :name_recursion_ref_ab : :name_recursion_ref_sq, text)
      when /^\\k(.)-?0*[1-9]\d*[+\-]\d+['>]$/
        emit(:backref, $1 == '<' ? :number_recursion_ref_ab : :number_recursion_ref_sq, text)
      else
        raise ValidationError.for(:backref, 'backreference', 'invalid ref ID')
      end
    };

    # Group call, named and numbered
    # ------------------------------------------------------------------------
    backslash . (group_call) > (backslashed, 4) {
      case text = copy(data, ts, te)
      when /^\\g(.)[^0-9+\-].*['>]$/
        emit(:backref, $1 == '<' ? :name_call_ab : :name_call_sq, text)
      when /^\\g(.)(?:0|0*[1-9]\d*)['>]$/
        emit(:backref, $1 == '<' ? :number_call_ab : :number_call_sq, text)
      when /^\\g(.)[+-]0*[1-9]\d*/
        emit(:backref, $1 == '<' ? :number_rel_call_ab : :number_rel_call_sq, text)
      else
        raise ValidationError.for(:backref, 'subexpression call', 'invalid ref ID')
      end
    };


    # Quantifiers
    # ------------------------------------------------------------------------
    zero_or_one {
      case text = copy(data, ts, te)
      when '?' ;  emit(:quantifier, :zero_or_one,            text)
      when '??';  emit(:quantifier, :zero_or_one_reluctant,  text)
      when '?+';  emit(:quantifier, :zero_or_one_possessive, text)
      end
    };

    zero_or_more {
      case text = copy(data, ts, te)
      when '*' ;  emit(:quantifier, :zero_or_more,            text)
      when '*?';  emit(:quantifier, :zero_or_more_reluctant,  text)
      when '*+';  emit(:quantifier, :zero_or_more_possessive, text)
      end
    };

    one_or_more {
      case text = copy(data, ts, te)
      when '+' ;  emit(:quantifier, :one_or_more,            text)
      when '+?';  emit(:quantifier, :one_or_more_reluctant,  text)
      when '++';  emit(:quantifier, :one_or_more_possessive, text)
      end
    };

    quantifier_interval {
      emit(:quantifier, :interval, copy(data, ts, te))
    };

    # Catch unmatched curly braces as literals
    range_open {
      append_literal(data, ts, te)
    };

    # Escaped sequences
    # ------------------------------------------------------------------------
    backslash > (backslashed, 1) {
      fcall escape_sequence;
    };

    comment {
      if free_spacing
        emit(:free_space, :comment, copy(data, ts, te))
      else
        # consume only the pound sign (#) and backtrack to do regular scanning
        append_literal(data, ts, ts + 1)
        fexec ts + 1;
      end
    };

    space+ {
      if free_spacing
        emit(:free_space, :whitespace, copy(data, ts, te))
      else
        append_literal(data, ts, te)
      end
    };

    # Literal: any run of ASCII (pritable or non-printable), and/or UTF-8,
    # except meta characters.
    # ------------------------------------------------------------------------
    (ascii_print -- space)+ | ascii_nonprint+ | utf8_multibyte+ {
      append_literal(data, ts, te)
    };

  *|;
}%%

require_relative 'scanner/errors/scanner_error'
require_relative 'scanner/errors/premature_end_error'
require_relative 'scanner/errors/validation_error'

class Regexp::Scanner
  # Scans the given regular expression text, or Regexp object and collects the
  # emitted token into an array that gets returned at the end. If a block is
  # given, it gets called for each emitted token.
  #
  # This method may raise errors if a syntax error is encountered.
  # --------------------------------------------------------------------------
  def self.scan(input_object, options: nil, collect_tokens: true, &block)
    new.scan(input_object, options: options, collect_tokens: collect_tokens, &block)
  end

  def scan(input_object, options: nil, collect_tokens: true, &block)
    self.collect_tokens = collect_tokens
    self.literal_run = nil
    stack = []

    input = input_object.is_a?(Regexp) ? input_object.source : input_object
    self.free_spacing = free_spacing?(input_object, options)
    self.spacing_stack = [{:free_spacing => free_spacing, :depth => 0}]

    data  = input.unpack("c*")
    eof   = data.length

    self.tokens = []
    self.block  = block

    self.set_depth = 0
    self.group_depth = 0
    self.conditional_stack = []
    self.char_pos = 0

    %% write data;
    %% write init;
    %% write exec;

    # to avoid "warning: assigned but unused variable - testEof"
    testEof = testEof

    if cs == re_scanner_error
      text = copy(data, ts ? ts-1 : 0, -1)
      raise ScannerError.new("Scan error at '#{text}'")
    end

    raise PrematureEndError.new("(missing group closing paranthesis) "+
          "[#{group_depth}]") if in_group?
    raise PrematureEndError.new("(missing set closing bracket) "+
          "[#{set_depth}]") if in_set?

    # when the entire expression is a literal run
    emit_literal if literal_run

    tokens
  end

  # lazy-load property maps when first needed
  def self.short_prop_map
    @short_prop_map ||= parse_prop_map('short')
  end

  def self.long_prop_map
    @long_prop_map ||= parse_prop_map('long')
  end

  def self.parse_prop_map(name)
    File.read("#{__dir__}/scanner/properties/#{name}.csv").scan(/(.+),(.+)/).to_h
  end

  def self.posix_classes
    %w[alnum alpha ascii blank cntrl digit graph
       lower print punct space upper word xdigit]
  end

  # Emits an array with the details of the scanned pattern
  def emit(type, token, text)
    #puts "EMIT: type: #{type}, token: #{token}, text: #{text}, ts: #{ts}, te: #{te}"

    emit_literal if literal_run

    # Ragel runs with byte-based indices (ts, te). These are of little value to
    # end-users, so we keep track of char-based indices and emit those instead.
    ts_char_pos = char_pos
    te_char_pos = char_pos + text.length

    tok = [type, token, text, ts_char_pos, te_char_pos]

    self.prev_token = tok

    self.char_pos = te_char_pos

    if block
      block.call type, token, text, ts_char_pos, te_char_pos
      # TODO: in v3.0.0, remove `collect_tokens:` kwarg and only collect if no block given
      tokens << tok if collect_tokens
    elsif collect_tokens
      tokens << tok
    end
  end

  attr_accessor :literal_run # only public for #||= to work on ruby <= 2.5

  private

  attr_accessor :block,
                :collect_tokens, :tokens, :prev_token,
                :free_spacing, :spacing_stack,
                :group_depth, :set_depth, :conditional_stack,
                :char_pos

  def free_spacing?(input_object, options)
    if options && !input_object.is_a?(String)
      raise ArgumentError, 'options cannot be supplied unless scanning a String'
    end

    options = input_object.options if input_object.is_a?(::Regexp)

    return false unless options

    options & Regexp::EXTENDED != 0
  end

  def in_group?
    group_depth > 0
  end

  def in_set?
    set_depth > 0
  end

  # Copy from ts to te from data as text
  def copy(data, ts, te)
    data[ts...te].pack('c*').force_encoding('utf-8')
  end

  # Appends one or more characters to the literal buffer, to be emitted later
  # by a call to emit_literal.
  def append_literal(data, ts, te)
    (self.literal_run ||= []) << copy(data, ts, te)
  end

  # Emits the literal run collected by calls to the append_literal method.
  def emit_literal
    text = literal_run.join
    self.literal_run = nil
    emit(:literal, :literal, text)
  end

  def emit_options(text)
    token = nil

    # Ruby allows things like '(?-xxxx)' or '(?xx-xx--xx-:abc)'.
    text =~ /\(\?([mixdau]*)(-(?:[mix]*))*(:)?/
    positive, negative, group_local = $1, $2, $3

    if positive.include?('x')
      self.free_spacing = true
    end

    # If the x appears in both, treat it like ruby does, the second cancels
    # the first.
    if negative && negative.include?('x')
      self.free_spacing = false
    end

    if group_local
      spacing_stack << {:free_spacing => free_spacing, :depth => group_depth}
      token = :options
    else
      # switch for parent group level
      spacing_stack.last[:free_spacing] = free_spacing
      token = :options_switch
    end

    emit(:group, token, text)
  end

  def emit_meta_control_sequence(data, ts, te, token)
    if data.last < 0x00 || data.last > 0x7F
      raise ValidationError.for(:sequence, 'escape', token.to_s)
    end
    emit(:escape, token, copy(data, ts-1, te))
  end
end # module Regexp::Scanner
