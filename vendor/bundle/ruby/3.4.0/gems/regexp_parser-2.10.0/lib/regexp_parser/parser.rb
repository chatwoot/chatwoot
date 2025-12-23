require_relative 'error'
require_relative 'expression'

class Regexp::Parser
  include Regexp::Expression

  class ParserError < Regexp::Parser::Error; end

  class UnknownTokenTypeError < ParserError
    def initialize(type, token)
      super "Unknown token type #{type} #{token.inspect}"
    end
  end

  class UnknownTokenError < ParserError
    def initialize(type, token)
      super "Unknown #{type} token #{token.token}"
    end
  end

  def self.parse(input, syntax = nil, options: nil, &block)
    new.parse(input, syntax, options: options, &block)
  end

  def parse(input, syntax = nil, options: nil, &block)
    root = Root.construct(options: extract_options(input, options))

    self.root = root
    self.node = root
    self.nesting = [root]

    self.options_stack = [root.options]
    self.switching_options = false
    self.conditional_nesting = []

    self.captured_group_counts = Hash.new(0)

    Regexp::Lexer.scan(input, syntax, options: options, collect_tokens: false) do |token|
      parse_token(token)
    end

    # Trigger recursive setting of #nesting_level, which reflects how deep
    # a node is in the tree. Do this at the end to account for tree rewrites.
    root.nesting_level = 0
    assign_referenced_expressions

    if block_given?
      block.call(root)
    else
      root
    end
  end

  private

  attr_accessor :root, :node, :nesting,
                :options_stack, :switching_options, :conditional_nesting,
                :captured_group_counts

  def extract_options(input, options)
    if options && !input.is_a?(String)
      raise ArgumentError, 'options cannot be supplied unless parsing a String'
    end

    options = input.options if input.is_a?(::Regexp)

    return {} unless options

    enabled_options = {}
    enabled_options[:i] = true if options & ::Regexp::IGNORECASE != 0
    enabled_options[:m] = true if options & ::Regexp::MULTILINE  != 0
    enabled_options[:x] = true if options & ::Regexp::EXTENDED   != 0
    enabled_options
  end

  def parse_token(token)
    case token.type
    when :anchor;                     anchor(token)
    when :assertion, :group;          group(token)
    when :backref;                    backref(token)
    when :conditional;                conditional(token)
    when :escape;                     escape(token)
    when :free_space;                 free_space(token)
    when :keep;                       keep(token)
    when :literal;                    literal(token)
    when :meta;                       meta(token)
    when :posixclass, :nonposixclass; posixclass(token)
    when :property, :nonproperty;     property(token)
    when :quantifier;                 quantifier(token)
    when :set;                        set(token)
    when :type;                       type(token)
    else
      raise UnknownTokenTypeError.new(token.type, token)
    end

    close_completed_character_set_range
  end

  def anchor(token)
    case token.token
    when :bol;              node << Anchor::BeginningOfLine.new(token, active_opts)
    when :bos;              node << Anchor::BOS.new(token, active_opts)
    when :eol;              node << Anchor::EndOfLine.new(token, active_opts)
    when :eos;              node << Anchor::EOS.new(token, active_opts)
    when :eos_ob_eol;       node << Anchor::EOSobEOL.new(token, active_opts)
    when :match_start;      node << Anchor::MatchStart.new(token, active_opts)
    when :nonword_boundary; node << Anchor::NonWordBoundary.new(token, active_opts)
    when :word_boundary;    node << Anchor::WordBoundary.new(token, active_opts)
    else
      raise UnknownTokenError.new('Anchor', token)
    end
  end

  def group(token)
    case token.token
    when :options, :options_switch
      options_group(token)
    when :close
      close_group
    when :comment
      node << Group::Comment.new(token, active_opts)
    else
      open_group(token)
    end
  end

  MOD_FLAGS = %w[i m x].map(&:to_sym)
  ENC_FLAGS = %w[a d u].map(&:to_sym)

  def options_group(token)
    positive, negative = token.text.split('-', 2)
    negative ||= ''
    self.switching_options = token.token.equal?(:options_switch)

    opt_changes = {}
    new_active_opts = active_opts.dup

    MOD_FLAGS.each do |flag|
      if positive.include?(flag.to_s)
        opt_changes[flag] = new_active_opts[flag] = true
      end
      if negative.include?(flag.to_s)
        opt_changes[flag] = false
        new_active_opts.delete(flag)
      end
    end

    if (enc_flag = positive.reverse[/[adu]/])
      enc_flag = enc_flag.to_sym
      (ENC_FLAGS - [enc_flag]).each do |other|
        opt_changes[other] = false if new_active_opts[other]
        new_active_opts.delete(other)
      end
      opt_changes[enc_flag] = new_active_opts[enc_flag] = true
    end

    options_stack << new_active_opts

    options_group = Group::Options.new(token, active_opts)
    options_group.option_changes = opt_changes

    nest(options_group)
  end

  def open_group(token)
    group_class =
      case token.token
      when :absence;     Group::Absence
      when :atomic;      Group::Atomic
      when :capture;     Group::Capture
      when :named;       Group::Named
      when :passive;     Group::Passive

      when :lookahead;   Assertion::Lookahead
      when :lookbehind;  Assertion::Lookbehind
      when :nlookahead;  Assertion::NegativeLookahead
      when :nlookbehind; Assertion::NegativeLookbehind

      else
        raise UnknownTokenError.new('Group type open', token)
      end

    group = group_class.new(token, active_opts)

    if group.capturing?
      group.number          = total_captured_group_count + 1
      group.number_at_level = captured_group_count_at_level + 1
      count_captured_group
    end

    # Push the active options to the stack again. This way we can simply pop the
    # stack for any group we close, no matter if it had its own options or not.
    options_stack << active_opts

    nest(group)
  end

  def total_captured_group_count
    captured_group_counts.values.reduce(0, :+)
  end

  def captured_group_count_at_level
    captured_group_counts[node]
  end

  def count_captured_group
    captured_group_counts[node] += 1
  end

  def close_group
    options_stack.pop unless switching_options
    self.switching_options = false
    decrease_nesting
  end

  def decrease_nesting
    while nesting.last.is_a?(SequenceOperation)
      nesting.pop
      self.node = nesting.last
    end
    nesting.pop
    yield(node) if block_given?
    self.node = nesting.last
    self.node = node.last if node.last.is_a?(SequenceOperation)
  end

  def backref(token)
    case token.token
    when :name_ref
      node << Backreference::Name.new(token, active_opts)
    when :name_recursion_ref
      node << Backreference::NameRecursionLevel.new(token, active_opts)
    when :name_call
      node << Backreference::NameCall.new(token, active_opts)
    when :number, :number_ref # TODO: split in v3.0.0
      node << Backreference::Number.new(token, active_opts)
    when :number_recursion_ref
      node << Backreference::NumberRecursionLevel.new(token, active_opts).tap do |exp|
        # TODO: should split off new token number_recursion_rel_ref and new
        # class NumberRelativeRecursionLevel in v3.0.0 to get rid of this
        if exp.text =~ /[<'][+-]/
          assign_effective_number(exp)
        else
          exp.effective_number = exp.number
        end
      end
    when :number_call
      node << Backreference::NumberCall.new(token, active_opts)
    when :number_rel_ref
      node << Backreference::NumberRelative.new(token, active_opts).tap do |exp|
        assign_effective_number(exp)
      end
    when :number_rel_call
      node << Backreference::NumberCallRelative.new(token, active_opts).tap do |exp|
        assign_effective_number(exp)
      end
    else
      raise UnknownTokenError.new('Backreference', token)
    end
  end

  def assign_effective_number(exp)
    exp.effective_number =
      exp.number + total_captured_group_count + (exp.number < 0 ? 1 : 0)
    exp.effective_number > 0 ||
      raise(ParserError, "Invalid reference: #{exp.reference}")
  end

  def conditional(token)
    case token.token
    when :open
      nest_conditional(Conditional::Expression.new(token, active_opts))
    when :condition
      conditional_nesting.last.condition = Conditional::Condition.new(token, active_opts)
      conditional_nesting.last.add_sequence(active_opts, { ts: token.te })
    when :separator
      conditional_nesting.last.add_sequence(active_opts, { ts: token.te })
      self.node = conditional_nesting.last.branches.last
    when :close
      conditional_nesting.pop
      decrease_nesting

      self.node =
        if conditional_nesting.empty?
          nesting.last
        else
          conditional_nesting.last
        end
    else
      raise UnknownTokenError.new('Conditional', token)
    end
  end

  def nest_conditional(exp)
    conditional_nesting.push(exp)
    nest(exp)
  end

  def nest(exp)
    nesting.push(exp)
    node << exp
    self.node = exp
  end

  def escape(token)
    case token.token

    when :backspace;      node << EscapeSequence::Backspace.new(token, active_opts)

    when :escape;         node << EscapeSequence::AsciiEscape.new(token, active_opts)
    when :bell;           node << EscapeSequence::Bell.new(token, active_opts)
    when :form_feed;      node << EscapeSequence::FormFeed.new(token, active_opts)
    when :newline;        node << EscapeSequence::Newline.new(token, active_opts)
    when :carriage;       node << EscapeSequence::Return.new(token, active_opts)
    when :tab;            node << EscapeSequence::Tab.new(token, active_opts)
    when :vertical_tab;   node << EscapeSequence::VerticalTab.new(token, active_opts)

    when :codepoint;      node << EscapeSequence::Codepoint.new(token, active_opts)
    when :codepoint_list; node << EscapeSequence::CodepointList.new(token, active_opts)
    when :hex;            node << EscapeSequence::Hex.new(token, active_opts)
    when :octal;          node << EscapeSequence::Octal.new(token, active_opts)

    when :control
      if token.text =~ /\A(?:\\C-\\M|\\c\\M)/
        # TODO: emit :meta_control_sequence token in v3.0.0
        node << EscapeSequence::MetaControl.new(token, active_opts)
      else
        node << EscapeSequence::Control.new(token, active_opts)
      end

    when :meta_sequence
      if token.text =~ /\A\\M-\\[Cc]/
        # TODO: emit :meta_control_sequence token in v3.0.0:
        node << EscapeSequence::MetaControl.new(token, active_opts)
      else
        node << EscapeSequence::Meta.new(token, active_opts)
      end

    else
      # treating everything else as a literal
      # TODO: maybe split this up a bit more in v3.0.0?
      # E.g. escaped quantifiers or set meta chars are not the same
      # as stuff that would be a literal even without the backslash.
      # Right now, they all end up here.
      node << EscapeSequence::Literal.new(token, active_opts)
    end
  end

  def free_space(token)
    case token.token
    when :comment
      node << Comment.new(token, active_opts)
    when :whitespace
      node << WhiteSpace.new(token, active_opts)
    else
      raise UnknownTokenError.new('FreeSpace', token)
    end
  end

  def keep(token)
    node << Keep::Mark.new(token, active_opts)
  end

  def literal(token)
    node << Literal.new(token, active_opts)
  end

  def meta(token)
    case token.token
    when :dot
      node << CharacterType::Any.new(token, active_opts)
    when :alternation
      sequence_operation(Alternation, token)
    else
      raise UnknownTokenError.new('Meta', token)
    end
  end

  def sequence_operation(klass, token)
    unless node.instance_of?(klass)
      operator = klass.new(token, active_opts)
      sequence = operator.add_sequence(active_opts, { ts: token.ts })
      sequence.expressions = node.expressions
      node.expressions = []
      nest(operator)
    end
    node.add_sequence(active_opts, { ts: token.te })
  end

  def posixclass(token)
    node << PosixClass.new(token, active_opts)
  end

  UP = Regexp::Expression::Property
  UPTokens = Regexp::Syntax::Token::Property

  def property(token)
    case token.token
    when :alnum;                  node << UP::Alnum.new(token, active_opts)
    when :alpha;                  node << UP::Alpha.new(token, active_opts)
    when :ascii;                  node << UP::Ascii.new(token, active_opts)
    when :blank;                  node << UP::Blank.new(token, active_opts)
    when :cntrl;                  node << UP::Cntrl.new(token, active_opts)
    when :digit;                  node << UP::Digit.new(token, active_opts)
    when :graph;                  node << UP::Graph.new(token, active_opts)
    when :lower;                  node << UP::Lower.new(token, active_opts)
    when :print;                  node << UP::Print.new(token, active_opts)
    when :punct;                  node << UP::Punct.new(token, active_opts)
    when :space;                  node << UP::Space.new(token, active_opts)
    when :upper;                  node << UP::Upper.new(token, active_opts)
    when :word;                   node << UP::Word.new(token, active_opts)
    when :xdigit;                 node << UP::Xdigit.new(token, active_opts)
    when :xposixpunct;            node << UP::XPosixPunct.new(token, active_opts)

    # only in Oniguruma (old rubies)
    when :newline;                node << UP::Newline.new(token, active_opts)

    when :any;                    node << UP::Any.new(token, active_opts)
    when :assigned;               node << UP::Assigned.new(token, active_opts)

    when :letter;                 node << UP::Letter::Any.new(token, active_opts)
    when :cased_letter;           node << UP::Letter::Cased.new(token, active_opts)
    when :uppercase_letter;       node << UP::Letter::Uppercase.new(token, active_opts)
    when :lowercase_letter;       node << UP::Letter::Lowercase.new(token, active_opts)
    when :titlecase_letter;       node << UP::Letter::Titlecase.new(token, active_opts)
    when :modifier_letter;        node << UP::Letter::Modifier.new(token, active_opts)
    when :other_letter;           node << UP::Letter::Other.new(token, active_opts)

    when :mark;                   node << UP::Mark::Any.new(token, active_opts)
    when :combining_mark;         node << UP::Mark::Combining.new(token, active_opts)
    when :nonspacing_mark;        node << UP::Mark::Nonspacing.new(token, active_opts)
    when :spacing_mark;           node << UP::Mark::Spacing.new(token, active_opts)
    when :enclosing_mark;         node << UP::Mark::Enclosing.new(token, active_opts)

    when :number;                 node << UP::Number::Any.new(token, active_opts)
    when :decimal_number;         node << UP::Number::Decimal.new(token, active_opts)
    when :letter_number;          node << UP::Number::Letter.new(token, active_opts)
    when :other_number;           node << UP::Number::Other.new(token, active_opts)

    when :punctuation;            node << UP::Punctuation::Any.new(token, active_opts)
    when :connector_punctuation;  node << UP::Punctuation::Connector.new(token, active_opts)
    when :dash_punctuation;       node << UP::Punctuation::Dash.new(token, active_opts)
    when :open_punctuation;       node << UP::Punctuation::Open.new(token, active_opts)
    when :close_punctuation;      node << UP::Punctuation::Close.new(token, active_opts)
    when :initial_punctuation;    node << UP::Punctuation::Initial.new(token, active_opts)
    when :final_punctuation;      node << UP::Punctuation::Final.new(token, active_opts)
    when :other_punctuation;      node << UP::Punctuation::Other.new(token, active_opts)

    when :separator;              node << UP::Separator::Any.new(token, active_opts)
    when :space_separator;        node << UP::Separator::Space.new(token, active_opts)
    when :line_separator;         node << UP::Separator::Line.new(token, active_opts)
    when :paragraph_separator;    node << UP::Separator::Paragraph.new(token, active_opts)

    when :symbol;                 node << UP::Symbol::Any.new(token, active_opts)
    when :math_symbol;            node << UP::Symbol::Math.new(token, active_opts)
    when :currency_symbol;        node << UP::Symbol::Currency.new(token, active_opts)
    when :modifier_symbol;        node << UP::Symbol::Modifier.new(token, active_opts)
    when :other_symbol;           node << UP::Symbol::Other.new(token, active_opts)

    when :other;                  node << UP::Codepoint::Any.new(token, active_opts)
    when :control;                node << UP::Codepoint::Control.new(token, active_opts)
    when :format;                 node << UP::Codepoint::Format.new(token, active_opts)
    when :surrogate;              node << UP::Codepoint::Surrogate.new(token, active_opts)
    when :private_use;            node << UP::Codepoint::PrivateUse.new(token, active_opts)
    when :unassigned;             node << UP::Codepoint::Unassigned.new(token, active_opts)

    when *UPTokens::Age;          node << UP::Age.new(token, active_opts)
    when *UPTokens::Derived;      node << UP::Derived.new(token, active_opts)
    when *UPTokens::Emoji;        node << UP::Emoji.new(token, active_opts)
    when *UPTokens::Enumerated;   node << UP::Enumerated.new(token, active_opts)
    when *UPTokens::Script;       node << UP::Script.new(token, active_opts)
    when *UPTokens::UnicodeBlock; node << UP::Block.new(token, active_opts)

    else
      raise UnknownTokenError.new('UnicodeProperty', token)
    end
  end

  def quantifier(token)
    target_node = node.extract_quantifier_target(token.text)

    # in case of chained quantifiers, wrap target in an implicit passive group
    # description of the problem: https://github.com/ammar/regexp_parser/issues/3
    # rationale for this solution: https://github.com/ammar/regexp_parser/pull/69
    if target_node.quantified?
      new_group = Group::Passive.construct(
        token:             :passive,
        ts:                target_node.ts,
        level:             target_node.level,
        set_level:         target_node.set_level,
        conditional_level: target_node.conditional_level,
        options:           active_opts,
      )
      new_group.implicit = true
      new_group << target_node
      increase_group_level(target_node)
      node.expressions[node.expressions.index(target_node)] = new_group
      target_node = new_group
    end

    unless token.token =~ /\A(?:zero_or_one|zero_or_more|one_or_more|interval)
                             (?:_greedy|_reluctant|_possessive)?\z/x
      raise UnknownTokenError.new('Quantifier', token)
    end

    target_node.quantify(token, active_opts)
  end

  def increase_group_level(exp)
    exp.level += 1
    exp.quantifier.level += 1 if exp.quantifier
    exp.terminal? || exp.each { |subexp| increase_group_level(subexp) }
  end

  def set(token)
    case token.token
    when :open;         open_set(token)
    when :close;        close_set
    when :negate;       negate_set
    when :range;        range(token)
    when :intersection; intersection(token)
    else
      raise UnknownTokenError.new('CharacterSet', token)
    end
  end

  def open_set(token)
    # TODO: this and Quantifier are the only cases where Expression#token
    # does not match the scanner/lexer output. Fix in v3.0.0.
    token.token = :character
    nest(CharacterSet.new(token, active_opts))
  end

  def negate_set
    node.negate
  end

  def close_set
    decrease_nesting(&:close)
  end

  def range(token)
    exp = CharacterSet::Range.new(token, active_opts)
    scope = node.last.instance_of?(CharacterSet::IntersectedSequence) ? node.last : node
    exp << scope.expressions.pop
    nest(exp)
  end

  def intersection(token)
    sequence_operation(CharacterSet::Intersection, token)
  end

  def type(token)
    case token.token
    when :digit;     node << CharacterType::Digit.new(token, active_opts)
    when :hex;       node << CharacterType::Hex.new(token, active_opts)
    when :linebreak; node << CharacterType::Linebreak.new(token, active_opts)
    when :nondigit;  node << CharacterType::NonDigit.new(token, active_opts)
    when :nonhex;    node << CharacterType::NonHex.new(token, active_opts)
    when :nonspace;  node << CharacterType::NonSpace.new(token, active_opts)
    when :nonword;   node << CharacterType::NonWord.new(token, active_opts)
    when :space;     node << CharacterType::Space.new(token, active_opts)
    when :word;      node << CharacterType::Word.new(token, active_opts)
    when :xgrapheme; node << CharacterType::ExtendedGrapheme.new(token, active_opts)
    else
      raise UnknownTokenError.new('CharacterType', token)
    end
  end

  def close_completed_character_set_range
    decrease_nesting if node.instance_of?(CharacterSet::Range) && node.complete?
  end

  def active_opts
    options_stack.last
  end

  # Assigns referenced expressions to referring expressions, e.g. if there is
  # an instance of Backreference::Number, its #referenced_expression is set to
  # the instance of Group::Capture that it refers to via its number.
  def assign_referenced_expressions
    # find all referenceable and referring expressions
    targets = { 0 => [root] }
    referrers = []
    root.each_expression do |exp|
      if exp.referential?
        referrers << exp
      elsif exp.is_a?(Group::Capture)
        (targets[exp.identifier] ||= []) << exp
      end
    end
    # assign referenced expressions to referring expressions
    # (in a second iteration because there might be forward references)
    referrers.each do |exp|
      exp.referenced_expressions = targets[exp.reference] ||
        raise(ParserError, "Invalid reference #{exp.reference} at pos #{exp.ts}")
    end
  end
end # module Regexp::Parser
