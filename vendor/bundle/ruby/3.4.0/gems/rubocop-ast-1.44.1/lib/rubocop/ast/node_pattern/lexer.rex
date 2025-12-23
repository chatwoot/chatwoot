# The only difficulty is to distinguish: `fn(argument)` from `fn (sequence)`.
# The presence of the whitespace determines if it is an _argument_ to the
# function call `fn` or if a _sequence_ follows the function call.
#
# If there is the potential for an argument list, the lexer enters the state `:ARG`.
# The rest of the times, the state is `nil`.
#
# In case of an argument list, :tARG_LIST is emitted instead of a '('.
# Therefore, the token '(' always signals the beginning of a sequence.

class RuboCop::AST::NodePattern::LexerRex

macros
        CONST_NAME                /[A-Z:][a-zA-Z_:]+/
        SYMBOL_NAME               /[\w+@*\/?!<>=~|%^&-]+|\[\]=?/
        IDENTIFIER                /[a-z][a-zA-Z0-9_]*/
        NODE_TYPE                 /[a-z][a-zA-Z0-9_-]*/  # Same as identifier but allows '-'
        CALL                      /(?:#{CONST_NAME}\.)?#{IDENTIFIER}[!?]?/
        REGEXP_BODY               /(?:[^\/]|\\\/)*/
        REGEXP                    /\/(#{REGEXP_BODY})(?<!\\)\/([imxo]*)/
rules
        /\s+/
        /:(#{SYMBOL_NAME})/o      { emit :tSYMBOL, &:to_sym }
        /"(.+?)"/                 { emit :tSTRING }
        /[-+]?\d+\.\d+/           { emit :tNUMBER, &:to_f }
        /[-+]?\d+/                { emit :tNUMBER, &:to_i }
        /#{Regexp.union(
          %w"( ) { | } [ ] < > $ ! ^ ` ... + * ? ,"
        )}/o                      { emit ss.matched, &:to_sym }
        /#{REGEXP}/o              { emit_regexp }
        /%?(#{CONST_NAME})/o      { emit :tPARAM_CONST }
        /%([a-z_]+)/              { emit :tPARAM_NAMED }
        /%(\d*)/                  { emit(:tPARAM_NUMBER) { |s| s.empty? ? 1 : s.to_i } } # Map `%` to `%1`
        /_(#{IDENTIFIER})/o       { emit :tUNIFY }
        /_/o                      { emit :tWILDCARD }
        /\#(#{CALL})/o            { @state = :ARG; emit :tFUNCTION_CALL, &:to_sym }
        /#{IDENTIFIER}\?/o        { @state = :ARG; emit :tPREDICATE, &:to_sym }
        /#{NODE_TYPE}/o           { emit :tNODE_TYPE, &:to_sym }
  :ARG  /\(/                      { @state = nil; emit :tARG_LIST }
  :ARG  //                        { @state = nil }
        /\#.*/                    { emit_comment }
end
