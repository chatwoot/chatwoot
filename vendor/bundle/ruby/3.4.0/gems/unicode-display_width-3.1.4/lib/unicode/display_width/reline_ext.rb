# Experimental
# Patches Reline's get_mbchar_width to use Unicode::DisplayWidth

require "reline"
require "reline/unicode"

require_relative "../display_width"

class Reline::Unicode
  def self.get_mbchar_width(mbchar)
    Unicode::DisplayWidth.of(mbchar, Reline.ambiguous_width)
  end
end

