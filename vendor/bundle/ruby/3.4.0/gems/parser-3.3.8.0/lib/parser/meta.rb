# frozen_string_literal: true

module Parser
  # Parser metadata
  module Meta

    # These are node types required by `Prism::Translation::Parser`, 
    # which has advanced syntax support ahead of the Parser gem.
    PRISM_TRANSLATION_PARSER_NODE_TYPES = %i(
      itarg itblock
    ).freeze
    private_constant :PRISM_TRANSLATION_PARSER_NODE_TYPES

    # All node types that parser can produce. Not all parser versions
    # will be able to produce every possible node.
    # Includes node types that are only emitted by the prism parser translator.
    NODE_TYPES = (
      %i(
        true false nil int float str dstr
        sym dsym xstr regopt regexp array splat
        pair kwsplat hash irange erange self
        lvar ivar cvar gvar const defined? lvasgn
        ivasgn cvasgn gvasgn casgn mlhs masgn
        op_asgn and_asgn ensure rescue arg_expr
        or_asgn back_ref nth_ref
        match_with_lvasgn match_current_line
        module class sclass def defs undef alias args
        cbase arg optarg restarg blockarg block_pass kwarg kwoptarg
        kwrestarg kwnilarg send csend super zsuper yield block
        and not or if when case while until while_post
        until_post for break next redo return resbody
        kwbegin begin retry preexe postexe iflipflop eflipflop
        shadowarg complex rational __FILE__ __LINE__ __ENCODING__
        ident lambda indexasgn index procarg0
        restarg_expr blockarg_expr
        objc_kwarg objc_restarg objc_varargs
        numargs numblock forward_args forwarded_args forward_arg
        case_match in_match in_pattern
        match_var pin match_alt match_as match_rest
        array_pattern match_with_trailing_comma array_pattern_with_tail
        hash_pattern const_pattern if_guard unless_guard match_nil_pattern
        empty_else find_pattern kwargs
        match_pattern_p match_pattern
        forwarded_restarg forwarded_kwrestarg
      ) + PRISM_TRANSLATION_PARSER_NODE_TYPES
    ).to_set.freeze
  end # Meta
end # Parser
