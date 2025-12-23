# frozen_string_literal: true

module RuboCop
  module AST
    # Common functionality between the parser and prism builder
    # @api private
    module BuilderExtensions
      def self.included(base)
        base.emit_forward_arg = true
        base.emit_match_pattern = true
      end

      # @api private
      NODE_MAP = {
        and:                 AndNode,
        and_asgn:            AndAsgnNode,
        alias:               AliasNode,
        arg:                 ArgNode,
        blockarg:            ArgNode,
        forward_arg:         ArgNode,
        kwarg:               ArgNode,
        kwoptarg:            ArgNode,
        kwrestarg:           ArgNode,
        optarg:              ArgNode,
        restarg:             ArgNode,
        shadowarg:           ArgNode,
        args:                ArgsNode,
        array:               ArrayNode,
        lvasgn:              AsgnNode,
        ivasgn:              AsgnNode,
        cvasgn:              AsgnNode,
        gvasgn:              AsgnNode,
        block:               BlockNode,
        numblock:            BlockNode,
        itblock:             BlockNode,
        break:               BreakNode,
        case_match:          CaseMatchNode,
        casgn:               CasgnNode,
        case:                CaseNode,
        class:               ClassNode,
        const:               ConstNode,
        def:                 DefNode,
        defined?:            DefinedNode,
        defs:                DefNode,
        dstr:                DstrNode,
        ensure:              EnsureNode,
        for:                 ForNode,
        forward_args:        ForwardArgsNode,
        forwarded_kwrestarg: KeywordSplatNode,
        float:               FloatNode,
        hash:                HashNode,
        if:                  IfNode,
        in_pattern:          InPatternNode,
        int:                 IntNode,
        index:               IndexNode,
        indexasgn:           IndexasgnNode,
        irange:              RangeNode,
        erange:              RangeNode,
        kwargs:              HashNode,
        kwbegin:             KeywordBeginNode,
        kwsplat:             KeywordSplatNode,
        lambda:              LambdaNode,
        masgn:               MasgnNode,
        mlhs:                MlhsNode,
        module:              ModuleNode,
        next:                NextNode,
        op_asgn:             OpAsgnNode,
        or_asgn:             OrAsgnNode,
        or:                  OrNode,
        pair:                PairNode,
        procarg0:            Procarg0Node,
        rational:            RationalNode,
        regexp:              RegexpNode,
        rescue:              RescueNode,
        resbody:             ResbodyNode,
        return:              ReturnNode,
        csend:               CsendNode,
        send:                SendNode,
        str:                 StrNode,
        xstr:                StrNode,
        sclass:              SelfClassNode,
        super:               SuperNode,
        zsuper:              SuperNode,
        sym:                 SymbolNode,
        until:               UntilNode,
        until_post:          UntilNode,
        lvar:                VarNode,
        ivar:                VarNode,
        cvar:                VarNode,
        gvar:                VarNode,
        when:                WhenNode,
        while:               WhileNode,
        while_post:          WhileNode,
        yield:               YieldNode
      }.freeze

      # Generates {Node} from the given information.
      #
      # @return [Node] the generated node
      def n(type, children, source_map)
        node_klass(type).new(type, children, location: source_map)
      end

      # Overwrite the base method to allow strings with invalid encoding
      # More details here https://github.com/whitequark/parser/issues/283
      def string_value(token)
        value(token)
      end

      private

      def node_klass(type)
        NODE_MAP[type] || Node
      end
    end

    # `RuboCop::AST::Builder` is an AST builder that is utilized to let `Parser`
    # generate ASTs with {RuboCop::AST::Node}.
    #
    # @example
    #   buffer = Parser::Source::Buffer.new('(string)')
    #   buffer.source = 'puts :foo'
    #
    #   builder = RuboCop::AST::Builder.new
    #   require 'parser/ruby25'
    #   parser = Parser::Ruby25.new(builder)
    #   root_node = parser.parse(buffer)
    class Builder < Parser::Builders::Default
      include BuilderExtensions
    end
  end
end
