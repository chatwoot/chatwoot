# Define the base module and the simplest of tokens.
module Regexp::Syntax
  module Token
    Map = {}

    module Literal
      All = %i[literal]
      Type = :literal
    end

    module FreeSpace
      All  = %i[comment whitespace]
      Type = :free_space
    end

    Map[FreeSpace::Type] = FreeSpace::All
    Map[Literal::Type]   = Literal::All
  end
end


# Load all the token files, they will populate the Map constant.
require_relative 'token/anchor'
require_relative 'token/assertion'
require_relative 'token/backreference'
require_relative 'token/posix_class'
require_relative 'token/character_set'
require_relative 'token/character_type'
require_relative 'token/conditional'
require_relative 'token/escape'
require_relative 'token/group'
require_relative 'token/keep'
require_relative 'token/meta'
require_relative 'token/quantifier'
require_relative 'token/unicode_property'


# After loading all the tokens the map is full. Extract all tokens and types
# into the All and Types constants.
module Regexp::Syntax
  module Token
    All   = Map.values.flatten.uniq.sort.freeze
    Types = Map.keys.freeze
  end
end
