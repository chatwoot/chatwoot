# frozen_string_literal: true

module Parser
  ##
  # Diagnostic messages (errors, warnings and notices) that can be generated.
  #
  # @see Diagnostic
  #
  # @api public
  #
  MESSAGES = {
    # Lexer errors
    :unicode_point_too_large  => 'invalid Unicode codepoint (too large)',
    :invalid_escape           => 'invalid escape character syntax',
    :incomplete_escape        => 'incomplete character syntax',
    :invalid_hex_escape       => 'invalid hex escape',
    :invalid_unicode_escape   => 'invalid Unicode escape',
    :unterminated_unicode     => 'unterminated Unicode escape',
    :escape_eof               => 'escape sequence meets end of file',
    :string_eof               => 'unterminated string meets end of file',
    :regexp_options           => 'unknown regexp options: %{options}',
    :cvar_name                => "`%{name}' is not allowed as a class variable name",
    :ivar_name                => "`%{name}' is not allowed as an instance variable name",
    :gvar_name                => "`%{name}' is not allowed as a global variable name",
    :trailing_in_number       => "trailing `%{character}' in number",
    :empty_numeric            => 'numeric literal without digits',
    :invalid_octal            => 'invalid octal digit',
    :no_dot_digit_literal     => 'no .<digit> floating literal anymore; put 0 before dot',
    :bare_backslash           => 'bare backslash only allowed before newline',
    :unexpected               => "unexpected `%{character}'",
    :embedded_document        => 'embedded document meets end of file (and they embark on a romantic journey)',
    :heredoc_id_has_newline   => 'here document identifier across newlines, never match',
    :heredoc_id_ends_with_nl  => 'here document identifier ends with a newline',
    :unterminated_heredoc_id  => 'unterminated heredoc id',

    # Lexer warnings
    :invalid_escape_use      => 'invalid character syntax; use ?%{escape}',
    :ambiguous_literal       => 'ambiguous first argument; put parentheses or a space even after the operator',
    :ambiguous_regexp        => "ambiguity between regexp and two divisions: wrap regexp in parentheses or add a space after `/' operator",
    :ambiguous_prefix        => "`%{prefix}' interpreted as argument prefix",
    :triple_dot_at_eol       => '... at EOL, should be parenthesized',

    # Parser errors
    :nth_ref_alias                 => 'cannot define an alias for a back-reference variable',
    :begin_in_method               => 'BEGIN in method',
    :backref_assignment            => 'cannot assign to a back-reference variable',
    :invalid_assignment            => 'cannot assign to a keyword',
    :module_name_const             => 'class or module name must be a constant literal',
    :unexpected_token              => 'unexpected token %{token}',
    :argument_const                => 'formal argument cannot be a constant',
    :argument_ivar                 => 'formal argument cannot be an instance variable',
    :argument_gvar                 => 'formal argument cannot be a global variable',
    :argument_cvar                 => 'formal argument cannot be a class variable',
    :duplicate_argument            => 'duplicate argument name',
    :empty_symbol                  => 'empty symbol literal',
    :odd_hash                      => 'odd number of entries for a hash',
    :singleton_literal             => 'cannot define a singleton method for a literal',
    :dynamic_const                 => 'dynamic constant assignment',
    :const_reassignment            => 'constant re-assignment',
    :module_in_def                 => 'module definition in method body',
    :class_in_def                  => 'class definition in method body',
    :unexpected_percent_str        => '%{type}: unknown type of percent-literal',
    :block_and_blockarg            => 'both block argument and literal block are passed',
    :masgn_as_condition            => 'multiple assignment in conditional context',
    :block_given_to_yield          => 'block given to yield',
    :invalid_regexp                => '%{message}',
    :invalid_return                => 'Invalid return in class/module body',
    :csend_in_lhs_of_masgn         => '&. inside multiple assignment destination',
    :cant_assign_to_numparam       => 'cannot assign to numbered parameter %{name}',
    :reserved_for_numparam         => '%{name} is reserved for numbered parameter',
    :ordinary_param_defined        => 'ordinary parameter is defined',
    :numparam_used_in_outer_scope  => 'numbered parameter is already used in an outer scope',
    :circular_argument_reference   => 'circular argument reference %{var_name}',
    :pm_interp_in_var_name         => 'symbol literal with interpolation is not allowed',
    :lvar_name                     => "`%{name}' is not allowed as a local variable name",
    :undefined_lvar                => "no such local variable: `%{name}'",
    :duplicate_variable_name       => 'duplicate variable name %{name}',
    :duplicate_pattern_key         => 'duplicate hash pattern key %{name}',
    :endless_setter                => 'setter method cannot be defined in an endless method definition',
    :invalid_id_to_get             => 'identifier %{identifier} is not valid to get',
    :forward_arg_after_restarg     => '... after rest argument',
    :no_anonymous_blockarg         => 'no anonymous block parameter',
    :no_anonymous_restarg          => 'no anonymous rest parameter',
    :no_anonymous_kwrestarg        => 'no anonymous keyword rest parameter',
    :ambiguous_anonymous_restarg   => 'anonymous rest parameter is also used within block',
    :ambiguous_anonymous_kwrestarg => 'anonymous keyword rest parameter is also used within block',
    :ambiguous_anonymous_blockarg  => 'anonymous block parameter is also used within block',

    # Parser warnings
    :useless_else            => 'else without rescue is useless',
    :duplicate_hash_key      => 'key is duplicated and overwritten',
    :ambiguous_it_call       => '`it` calls without arguments refers to the first block param',

    # Parser errors that are not Ruby errors
    :invalid_encoding        => 'literal contains escape sequences incompatible with UTF-8',

    # Rewriter diagnostics
    :invalid_action          => 'cannot %{action}',
    :clobbered               => 'clobbered by: %{action}',

    # Rewriter diagnostics
    :different_replacements        => 'different replacements: %{replacement} vs %{other_replacement}',
    :swallowed_insertions          => 'this replacement:',
    :swallowed_insertions_conflict => 'swallows some inner rewriting actions:',
    :crossing_deletions            => 'the deletion of:',
    :crossing_deletions_conflict   => 'is crossing:',
    :crossing_insertions           => 'the rewriting action on:',
    :crossing_insertions_conflict  => 'is crossing that on:',
  }.freeze

  # @api private
  module Messages
    # Formats the message, returns a raw template if there's nothing to interpolate
    #
    # Code like `format("", {})` gives a warning, and so this method tries interpolating
    # only if `arguments` hash is not empty.
    #
    # @api private
    def self.compile(reason, arguments)
      template = MESSAGES[reason]
      return template if Hash === arguments && arguments.empty?
      format(template, arguments)
    end
  end
end
