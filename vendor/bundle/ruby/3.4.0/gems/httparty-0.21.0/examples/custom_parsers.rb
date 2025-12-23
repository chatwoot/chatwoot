dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require File.join(dir, 'httparty')
require 'pp'

class ParseAtom
  include HTTParty

  # Support Atom along with the default parsers: xml, json, etc.
  class Parser::Atom < HTTParty::Parser
    SupportedFormats.merge!({"application/atom+xml" => :atom})

    protected

    # perform atom parsing on body
    def atom
      body.to_atom
    end
  end

  parser Parser::Atom
end

class OnlyParseAtom
  include HTTParty

  # Only support Atom
  class Parser::OnlyAtom < HTTParty::Parser
    SupportedFormats = { "application/atom+xml" => :atom }

    protected

    # perform atom parsing on body
    def atom
      body.to_atom
    end
  end

  parser Parser::OnlyAtom
end

class SkipParsing
  include HTTParty

  # Parse the response body however you like
  class Parser::Simple < HTTParty::Parser
    def parse
      body
    end
  end

  parser Parser::Simple
end

class AdHocParsing
  include HTTParty
  parser(
    proc do |body, format|
      case format
      when :json
        body.to_json
      when :xml
        body.to_xml
      else
        body
      end
    end
  )
end
