class RuboCop::AST::NodePattern::Parser
options no_result_var
token tSYMBOL tNUMBER tSTRING tWILDCARD tPARAM_NAMED tPARAM_CONST tPARAM_NUMBER
      tFUNCTION_CALL tPREDICATE tNODE_TYPE tARG_LIST tUNIFY tREGEXP
rule
  node_pattern                               # @return Node
    : node_pattern_no_union
    | union                                  { enforce_unary(val[0]) }
    ;

  node_pattern_no_union                      # @return Node
    : '(' variadic_pattern_list ')'          { emit_list :sequence, *val }
    | '[' node_pattern_list ']'              { emit_list :intersection, *val }
    | '!' node_pattern                       { emit_unary_op :negation, *val }
    | '^' node_pattern                       { emit_unary_op :ascend, *val }
    | '`' node_pattern                       { emit_unary_op :descend, *val }
    | '$' node_pattern                       { emit_capture(*val) }
    | tFUNCTION_CALL args                    { emit_call :function_call, *val }
    | tPREDICATE args                        { emit_call :predicate, *val }
    | tNODE_TYPE                             { emit_call :node_type, *val }
    | atom
    ;

  atom                                       # @return Node
    : tSYMBOL                                { emit_atom :symbol, *val }
    | tNUMBER                                { emit_atom :number, *val }
    | tSTRING                                { emit_atom :string, *val }
    | tPARAM_CONST                           { emit_atom :const, *val }
    | tPARAM_NAMED                           { emit_atom :named_parameter, *val }
    | tPARAM_NUMBER                          { emit_atom :positional_parameter, *val }
    | tREGEXP                                { emit_atom :regexp, *val }
    | tWILDCARD                              { emit_atom :wildcard, *val }
    | tUNIFY                                 { emit_atom :unify, *val }
    ;

  union                                      # @return Node
    : '{' separated_variadic_patterns '}'    { emit_union(*val) }
    ;

  variadic_pattern                           # @return Node
    : node_pattern_no_union
    | union
    | node_pattern repetition
      {
        main, repeat_t = val
        emit_unary_op(:repetition, repeat_t, main, repeat_t)
      }
    | opt_capture '<' node_pattern_list opt_rest '>'
      {
        opt_capture, bracket, node_pattern_list, opt_rest, close_bracket = val
        node_pattern_list << opt_rest if opt_rest
        main = emit_list :any_order, bracket, node_pattern_list, close_bracket
        emit_capture(opt_capture, main)
      }
    | rest
    ;

  repetition                                 # @return Token
    : '?'
    | '*'
    | '+'
    ;

  opt_capture                                # @return Token | nil
    :
    | '$'
    ;

  rest                                       # @return Node
    : opt_capture '...'                      { emit_capture(val[0], emit_atom(:rest, val[1])) }
    ;

  opt_rest                                   # @return Node | nil
    :
    | rest
    ;

  args                                       # @return [Token, Array<Node>, Token] | nil
    :
    | tARG_LIST arg_list ')'                 { val }
    ;

  arg_list                                   # @return Array<Node>
    : node_pattern                           { val }
    | arg_list ',' node_pattern              { val[0] << val[2] }
    ;

  node_pattern_list                          # @return Array<Node>
    : node_pattern                           { val }
    | node_pattern_list node_pattern         { val[0] << val[1] }
    ;

  variadic_pattern_list                      # @return Array<Node>
    : variadic_pattern                       { val }
    | variadic_pattern_list variadic_pattern { val[0] << val[1] }
    ;

  separated_variadic_patterns                # @return Array<Array<Node>>
    :                                        { [[]] }
    | separated_variadic_patterns variadic_pattern { val[0].last << val[1]; val[0] }
    | separated_variadic_patterns '|'        { val[0] << [] }
    ;
end
