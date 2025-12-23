module Brakeman
  module Messages
    # Create a new message from a list of messages.
    # Strings are converted to Brakeman::Messages::Plain objects.
    def msg *args
      parts = args.map do |a|
        if a.is_a? String
          Plain.new(a)
        else
          a
        end
      end

      Message.new(*parts)
    end

    # Create a new code message fragment
    def msg_code code
      Code.new code
    end

    # Create a new message fragment with a CVE identifier
    def msg_cve cve
      CVE.new cve
    end

    # Create a new message fragment representing a file name
    def msg_file str
      Messages::FileName.new str
    end

    # Create a new message fragment from a user input type (e.g. `:params`).
    # The input type will be converted to a friendly version (e.g. "parameter value").
    def msg_input input
      Input.new input
    end

    # Create a new message fragment which will not be modified during output
    def msg_lit str
      Literal.new str
    end

    # Create a new plain string message fragment
    def msg_plain str
      Plain.new str
    end

    # Create a message fragment representing the version of a library
    def msg_version version, lib = "Rails"
      Version.new version, lib
    end
  end
end

# Class to represent a list of message types
class Brakeman::Messages::Message
  def initialize *args
    @parts = args.map do |a|
      case a
      when String, Symbol
        Brakeman::Messages::Plain.new(a.to_s)
      else
        a
      end
    end
  end

  def << msg
    if msg.is_a? String
      @parts << Brakeman::Messages::Plain.new(msg)
    else
      @parts << msg
    end
  end

  def to_s
    output = @parts.map(&:to_s).join

    case @parts.first
    when Brakeman::Messages::Code, Brakeman::Messages::Literal, Brakeman::Messages::Version
    else
      output[0] = output[0].capitalize
    end

    output
  end

  def to_html
    require 'cgi'

    output = @parts.map(&:to_html).join

    case @parts.first
    when Brakeman::Messages::Code, Brakeman::Messages::Literal, Brakeman::Messages::Version
    else
      output[0] = output[0].capitalize
    end

    output
  end
end

class Brakeman::Messages::Code
  def initialize code
    @code = code.to_s
  end

  def to_s
    "`#{@code}`"
  end

  def to_html
    "<span class=\"code\">#{CGI.escapeHTML(@code)}</span>"
  end
end

class Brakeman::Messages::CVE
  def initialize cve
    @cve = cve
  end

  def to_s
    "(#{@cve})"
  end

  def to_html
    "(<a href=\"https://cve.mitre.org/cgi-bin/cvename.cgi?name=#{@cve}\" target=\"_blank\" rel=\"noreferrer\">#{@cve}</a>)"
  end
end

class Brakeman::Messages::FileName
  def initialize file
    @file = file
  end

  def to_s
    "`#{@file}`"
  end

  def to_html
    "<span class=\"filename\">#{CGI.escapeHTML(@file)}</span>"
  end
end

class Brakeman::Messages::Input
  def initialize input
    @input = input
    @value = friendly_type_of(@input)
  end

  def friendly_type_of input_type
    if input_type.is_a? Brakeman::BaseCheck::Match
      input_type = input_type.type
    end

    case input_type
    when :params
      "parameter value"
    when :cookies
      "cookie value"
    when :request
      "request value"
    when :model
      "model attribute"
    else
      "user input"
    end
  end

  def to_s
    @value
  end

  def to_html
    self.to_s
  end
end

class Brakeman::Messages::Literal
  def initialize value
    @value = value.to_s
  end

  def to_s
    @value
  end

  def to_html
    @value
  end
end

class Brakeman::Messages::Plain
  def initialize string
    @value = string
  end

  def to_s
    @value
  end

  def to_html
    CGI.escapeHTML(@value)
  end
end

class Brakeman::Messages::Version
  def initialize version, lib
    @version = version
    @library = lib
  end

  def to_s
    "#{@library} #{@version}"
  end

  def to_html
    CGI.escapeHTML(self.to_s)
  end
end
