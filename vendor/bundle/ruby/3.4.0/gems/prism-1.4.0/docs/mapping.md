# Mapping

When considering the previous CRuby parser versus prism, this document should be helpful to understand how various concepts are mapped.

## Nodes

The following table shows how the various CRuby nodes are mapped to prism nodes.

| CRuby | prism |
| --- | --- |
| `NODE_SCOPE` | |
| `NODE_BLOCK` | |
| `NODE_IF` | `PM_IF_NODE` |
| `NODE_UNLESS` | `PM_UNLESS_NODE` |
| `NODE_CASE` | `PM_CASE_NODE` |
| `NODE_CASE2` | `PM_CASE_NODE` (with a null predicate) |
| `NODE_CASE3` | |
| `NODE_WHEN` | `PM_WHEN_NODE` |
| `NODE_IN` | `PM_IN_NODE` |
| `NODE_WHILE` | `PM_WHILE_NODE` |
| `NODE_UNTIL` | `PM_UNTIL_NODE` |
| `NODE_ITER` | `PM_CALL_NODE` (with a non-null block) |
| `NODE_FOR` | `PM_FOR_NODE` |
| `NODE_FOR_MASGN` | `PM_FOR_NODE` (with a multi-write node as the index) |
| `NODE_BREAK` | `PM_BREAK_NODE` |
| `NODE_NEXT` | `PM_NEXT_NODE` |
| `NODE_REDO` | `PM_REDO_NODE` |
| `NODE_RETRY` | `PM_RETRY_NODE` |
| `NODE_BEGIN` | `PM_BEGIN_NODE` |
| `NODE_RESCUE` | `PM_RESCUE_NODE` |
| `NODE_RESBODY` | |
| `NODE_ENSURE` | `PM_ENSURE_NODE` |
| `NODE_AND` | `PM_AND_NODE` |
| `NODE_OR` | `PM_OR_NODE` |
| `NODE_MASGN` | `PM_MULTI_WRITE_NODE` |
| `NODE_LASGN` | `PM_LOCAL_VARIABLE_WRITE_NODE` |
| `NODE_DASGN` | `PM_LOCAL_VARIABLE_WRITE_NODE` |
| `NODE_GASGN` | `PM_GLOBAL_VARIABLE_WRITE_NODE` |
| `NODE_IASGN` | `PM_INSTANCE_VARIABLE_WRITE_NODE` |
| `NODE_CDECL` | `PM_CONSTANT_PATH_WRITE_NODE` |
| `NODE_CVASGN` | `PM_CLASS_VARIABLE_WRITE_NODE` |
| `NODE_OP_ASGN1` | |
| `NODE_OP_ASGN2` | |
| `NODE_OP_ASGN_AND` | `PM_OPERATOR_AND_ASSIGNMENT_NODE` |
| `NODE_OP_ASGN_OR` | `PM_OPERATOR_OR_ASSIGNMENT_NODE` |
| `NODE_OP_CDECL` | |
| `NODE_CALL` | `PM_CALL_NODE` |
| `NODE_OPCALL` | `PM_CALL_NODE` (with an operator as the method) |
| `NODE_FCALL` | `PM_CALL_NODE` (with a null receiver and parentheses) |
| `NODE_VCALL` | `PM_CALL_NODE` (with a null receiver and parentheses or arguments) |
| `NODE_QCALL` | `PM_CALL_NODE` (with a &. operator) |
| `NODE_SUPER` | `PM_SUPER_NODE` |
| `NODE_ZSUPER` | `PM_FORWARDING_SUPER_NODE` |
| `NODE_LIST` | `PM_ARRAY_NODE` |
| `NODE_ZLIST` | `PM_ARRAY_NODE` (with no child elements) |
| `NODE_VALUES` | `PM_ARGUMENTS_NODE` |
| `NODE_HASH` | `PM_HASH_NODE` |
| `NODE_RETURN` | `PM_RETURN_NODE` |
| `NODE_YIELD` | `PM_YIELD_NODE` |
| `NODE_LVAR` | `PM_LOCAL_VARIABLE_READ_NODE` |
| `NODE_DVAR` | `PM_LOCAL_VARIABLE_READ_NODE` |
| `NODE_GVAR` | `PM_GLOBAL_VARIABLE_READ_NODE` |
| `NODE_IVAR` | `PM_INSTANCE_VARIABLE_READ_NODE` |
| `NODE_CONST` | `PM_CONSTANT_PATH_READ_NODE` |
| `NODE_CVAR` | `PM_CLASS_VARIABLE_READ_NODE` |
| `NODE_NTH_REF` | `PM_NUMBERED_REFERENCE_READ_NODE` |
| `NODE_BACK_REF` | `PM_BACK_REFERENCE_READ_NODE` |
| `NODE_MATCH` | |
| `NODE_MATCH2` | `PM_CALL_NODE` (with regular expression as receiver) |
| `NODE_MATCH3` | `PM_CALL_NODE` (with regular expression as only argument) |
| `NODE_LIT` | |
| `NODE_STR` | `PM_STRING_NODE` |
| `NODE_DSTR` | `PM_INTERPOLATED_STRING_NODE` |
| `NODE_XSTR` | `PM_X_STRING_NODE` |
| `NODE_DXSTR` | `PM_INTERPOLATED_X_STRING_NODE` |
| `NODE_EVSTR` | `PM_STRING_INTERPOLATED_NODE` |
| `NODE_DREGX` | `PM_INTERPOLATED_REGULAR_EXPRESSION_NODE` |
| `NODE_ONCE` | |
| `NODE_ARGS` | `PM_PARAMETERS_NODE` |
| `NODE_ARGS_AUX` | |
| `NODE_OPT_ARG` | `PM_OPTIONAL_PARAMETER_NODE` |
| `NODE_KW_ARG` | `PM_KEYWORD_PARAMETER_NODE` |
| `NODE_POSTARG` | `PM_REQUIRED_PARAMETER_NODE` |
| `NODE_ARGSCAT` | |
| `NODE_ARGSPUSH` | |
| `NODE_SPLAT` | `PM_SPLAT_NODE` |
| `NODE_BLOCK_PASS` | `PM_BLOCK_ARGUMENT_NODE` |
| `NODE_DEFN` | `PM_DEF_NODE` (with a null receiver) |
| `NODE_DEFS` | `PM_DEF_NODE` (with a non-null receiver) |
| `NODE_ALIAS` | `PM_ALIAS_NODE` |
| `NODE_VALIAS` | `PM_ALIAS_NODE` (with a global variable first argument) |
| `NODE_UNDEF` | `PM_UNDEF_NODE` |
| `NODE_CLASS` | `PM_CLASS_NODE` |
| `NODE_MODULE` | `PM_MODULE_NODE` |
| `NODE_SCLASS` | `PM_S_CLASS_NODE` |
| `NODE_COLON2` | `PM_CONSTANT_PATH_NODE` |
| `NODE_COLON3` | `PM_CONSTANT_PATH_NODE` (with a null receiver) |
| `NODE_DOT2` | `PM_RANGE_NODE` (with a .. operator) |
| `NODE_DOT3` | `PM_RANGE_NODE` (with a ... operator) |
| `NODE_FLIP2` | `PM_RANGE_NODE` (with a .. operator) |
| `NODE_FLIP3` | `PM_RANGE_NODE` (with a ... operator) |
| `NODE_SELF` | `PM_SELF_NODE` |
| `NODE_NIL` | `PM_NIL_NODE` |
| `NODE_TRUE` | `PM_TRUE_NODE` |
| `NODE_FALSE` | `PM_FALSE_NODE` |
| `NODE_ERRINFO` | |
| `NODE_DEFINED` | `PM_DEFINED_NODE` |
| `NODE_POSTEXE` | `PM_POST_EXECUTION_NODE` |
| `NODE_DSYM` | `PM_INTERPOLATED_SYMBOL_NODE` |
| `NODE_ATTRASGN` | `PM_CALL_NODE` (with a message that ends with =) |
| `NODE_LAMBDA` | `PM_LAMBDA_NODE` |
| `NODE_ARYPTN` | `PM_ARRAY_PATTERN_NODE` |
| `NODE_HSHPTN` | `PM_HASH_PATTERN_NODE` |
| `NODE_FNDPTN` | `PM_FIND_PATTERN_NODE` |
| `NODE_ERROR` | `PM_MISSING_NODE` |
| `NODE_LAST` | |
```
