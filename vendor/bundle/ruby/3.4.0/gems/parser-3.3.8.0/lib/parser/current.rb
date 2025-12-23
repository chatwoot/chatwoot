# frozen_string_literal: true

module Parser
  class << self
    def warn_syntax_deviation(feature, version)
      warn "warning: parser/current is loading #{feature}, which recognizes " \
        "#{version}-compliant syntax, but you are running #{RUBY_VERSION}.\n" \
        "Please see https://github.com/whitequark/parser#compatibility-with-ruby-mri."
    end
    private :warn_syntax_deviation
  end

  case RUBY_VERSION
  when /^2\.0\./
    current_version = '2.0.0'
    if RUBY_VERSION != current_version
      warn_syntax_deviation 'parser/ruby20', current_version
    end

    require_relative 'ruby20'
    CurrentRuby = Ruby20

  when /^2\.1\./
    current_version = '2.1.10'
    if RUBY_VERSION != current_version
      warn_syntax_deviation 'parser/ruby21', current_version
    end

    require_relative 'ruby21'
    CurrentRuby = Ruby21

  when /^2\.2\./
    current_version = '2.2.10'
    if RUBY_VERSION != current_version
      warn_syntax_deviation 'parser/ruby22', current_version
    end

    require_relative 'ruby22'
    CurrentRuby = Ruby22

  when /^2\.3\./
    current_version = '2.3.8'
    if RUBY_VERSION != current_version
      warn_syntax_deviation 'parser/ruby23', current_version
    end

    require_relative 'ruby23'
    CurrentRuby = Ruby23

  when /^2\.4\./
    current_version = '2.4.10'
    if RUBY_VERSION != current_version
      warn_syntax_deviation 'parser/ruby24', current_version
    end

    require_relative 'ruby24'
    CurrentRuby = Ruby24

  when /^2\.5\./
    current_version = '2.5.9'
    if RUBY_VERSION != current_version
      warn_syntax_deviation 'parser/ruby25', current_version
    end

    require_relative 'ruby25'
    CurrentRuby = Ruby25

  when /^2\.6\./
    current_version = '2.6.10'
    if RUBY_VERSION != current_version
      warn_syntax_deviation 'parser/ruby26', current_version
    end

    require_relative 'ruby26'
    CurrentRuby = Ruby26

  when /^2\.7\./
    current_version = '2.7.8'
    if RUBY_VERSION != current_version
      warn_syntax_deviation 'parser/ruby27', current_version
    end

    require_relative 'ruby27'
    CurrentRuby = Ruby27

  when /^3\.0\./
    current_version = '3.0.7'
    if RUBY_VERSION != current_version
      warn_syntax_deviation 'parser/ruby30', current_version
    end

    require_relative 'ruby30'
    CurrentRuby = Ruby30

  when /^3\.1\./
    current_version = '3.1.7'
    if RUBY_VERSION != current_version
      warn_syntax_deviation 'parser/ruby31', current_version
    end

    require_relative 'ruby31'
    CurrentRuby = Ruby31

  when /^3\.2\./
    current_version = '3.2.8'
    if RUBY_VERSION != current_version
      warn_syntax_deviation 'parser/ruby32', current_version
    end

    require_relative 'ruby32'
    CurrentRuby = Ruby32

  when /^3\.3\./
    current_version = '3.3.8'
    if RUBY_VERSION != current_version
      warn_syntax_deviation 'parser/ruby33', current_version
    end

    require_relative 'ruby33'
    CurrentRuby = Ruby33

  when /^3\.4\./
    current_version = '3.4.0-dev'
    if RUBY_VERSION != current_version
      warn_syntax_deviation 'parser/ruby34', current_version
    end

    require_relative 'ruby34'
    CurrentRuby = Ruby34

  else # :nocov:
    # Keep this in sync with released Ruby.
    warn_syntax_deviation 'parser/ruby33', '3.3.x'
    require_relative 'ruby33'
    CurrentRuby = Ruby33
  end
  # @!parse
  #  ##
  #  # @api public
  #  #
  #  # Parser for the running version of Ruby. NOTE: Supports only Ruby <= 3.3. To parse Ruby 3.4+, please use the prism gem. You can also use them in conjunction to support multiple versions using a backwards-compatible AST.
  #  #
  #  # @see https://ruby.github.io/prism/rb/docs/ruby_api_md.html prism gem documentation
  #  # @see https://github.com/whitequark/parser/blob/master/doc/PRISM_TRANSLATION.md Guide to using prism and parser together.
  #  class ::Parser::CurrentRuby < ::Parser::Base; end
end
