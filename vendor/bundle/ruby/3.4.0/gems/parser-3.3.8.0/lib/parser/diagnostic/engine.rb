# frozen_string_literal: true

module Parser

  ##
  # {Parser::Diagnostic::Engine} provides a basic API for dealing with
  # diagnostics by delegating them to registered consumers.
  #
  # @example
  #  buffer      = Parser::Source::Buffer.new(__FILE__, source: 'foobar')
  #
  #  consumer = lambda do |diagnostic|
  #    puts diagnostic.message
  #  end
  #
  #  engine     = Parser::Diagnostic::Engine.new(consumer)
  #  diagnostic = Parser::Diagnostic.new(
  #      :warning, :unexpected_token, { :token => 'abc' }, buffer, 1..2)
  #
  #  engine.process(diagnostic) # => "unexpected token abc"
  #
  # @api public
  #
  # @!attribute [rw] consumer
  #  @return [#call(Diagnostic)]
  #
  # @!attribute [rw] all_errors_are_fatal
  #  When set to `true` any error that is encountered will result in
  #  {Parser::SyntaxError} being raised.
  #  @return [Boolean]
  #
  # @!attribute [rw] ignore_warnings
  #  When set to `true` warnings will be ignored.
  #  @return [Boolean]
  #
  class Diagnostic::Engine
    attr_accessor :consumer

    attr_accessor :all_errors_are_fatal
    attr_accessor :ignore_warnings

    ##
    # @param [#call(Diagnostic)] consumer
    #
    def initialize(consumer=nil)
      @consumer             = consumer

      @all_errors_are_fatal = false
      @ignore_warnings      = false
    end

    ##
    # Processes a `diagnostic`:
    #   * Passes the diagnostic to the consumer, if it's not a warning when
    #     `ignore_warnings` is set.
    #   * After that, raises {Parser::SyntaxError} when `all_errors_are_fatal`
    #     is set to true.
    #
    # @param [Parser::Diagnostic] diagnostic
    # @return [Parser::Diagnostic::Engine]
    # @see ignore?
    # @see raise?
    #
    def process(diagnostic)
      if ignore?(diagnostic)
        # do nothing
      elsif @consumer
        @consumer.call(diagnostic)
      end

      if raise?(diagnostic)
        raise Parser::SyntaxError, diagnostic
      end

      self
    end

    protected

    ##
    # Checks whether `diagnostic` should be ignored.
    #
    # @param [Parser::Diagnostic] diagnostic
    # @return [Boolean]
    #
    def ignore?(diagnostic)
      @ignore_warnings &&
            diagnostic.level == :warning
    end

    ##
    # Checks whether `diagnostic` should be raised as an exception.
    #
    # @param [Parser::Diagnostic] diagnostic
    # @return [Boolean]
    #
    def raise?(diagnostic)
      (@all_errors_are_fatal &&
          diagnostic.level == :error) ||
        diagnostic.level == :fatal
    end
  end

end
