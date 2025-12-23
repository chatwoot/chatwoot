module LanguageServer
  module Protocol
    module Constant
      module SemanticTokenTypes
        NAMESPACE = 'namespace'
        #
        # Represents a generic type. Acts as a fallback for types which
        # can't be mapped to a specific type like class or enum.
        #
        TYPE = 'type'
        CLASS = 'class'
        ENUM = 'enum'
        INTERFACE = 'interface'
        STRUCT = 'struct'
        TYPE_PARAMETER = 'typeParameter'
        PARAMETER = 'parameter'
        VARIABLE = 'variable'
        PROPERTY = 'property'
        ENUM_MEMBER = 'enumMember'
        EVENT = 'event'
        FUNCTION = 'function'
        METHOD = 'method'
        MACRO = 'macro'
        KEYWORD = 'keyword'
        MODIFIER = 'modifier'
        COMMENT = 'comment'
        STRING = 'string'
        NUMBER = 'number'
        REGEXP = 'regexp'
        OPERATOR = 'operator'
        DECORATOR = 'decorator'
      end
    end
  end
end
