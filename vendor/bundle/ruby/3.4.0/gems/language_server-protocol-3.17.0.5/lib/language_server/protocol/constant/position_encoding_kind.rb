module LanguageServer
  module Protocol
    module Constant
      #
      # A type indicating how positions are encoded,
      # specifically what column offsets mean.
      # A set of predefined position encoding kinds.
      #
      module PositionEncodingKind
        #
        # Character offsets count UTF-8 code units (e.g bytes).
        #
        UTF8 = 'utf-8'
        #
        # Character offsets count UTF-16 code units.
        #
        # This is the default and must always be supported
        # by servers
        #
        UTF16 = 'utf-16'
        #
        # Character offsets count UTF-32 code units.
        #
        # Implementation note: these are the same as Unicode code points,
        # so this `PositionEncodingKind` may also be used for an
        # encoding-agnostic representation of character offsets.
        #
        UTF32 = 'utf-32'
      end
    end
  end
end
