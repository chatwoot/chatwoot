require "racc/parser"

class RubyParser
  module Legacy
  end
end

require "ruby_parser/legacy/ruby_parser_extras"
require "ruby_parser"

class RubyParser
  module Legacy
    class RubyParser < ::RubyParser::Parser
      include ::RubyParser::Legacy::RubyParserStuff
    end
  end
end

require "ruby_parser/legacy/ruby19_parser"
require "ruby_parser/legacy/ruby18_parser"


class ::RubyParser # Plug into modern system
  VERSIONS.delete ::RubyParser::Legacy::RubyParser
  VERSIONS.delete Ruby19Parser
  VERSIONS.delete Ruby18Parser

  class V19 < ::Ruby19Parser; end
  class V18 < ::Ruby18Parser; end
end
