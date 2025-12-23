module Oj
  # A SAX style parse handler for JSON hence the acronym SAJ for Simple API
  # for JSON. The Oj::Saj handler class can be subclassed and then used with
  # the Oj::Saj key_parse() method or with the more resent
  # Oj::Parser.new(:saj). The Saj methods will then be called as the file is
  # parsed.
  #
  # With Oj::Parser.new(:saj) each method can also include a line and column
  # argument so hash_start(key) could also be hash_start(key, line,
  # column). The error() method is no used with Oj::Parser.new(:saj) so it
  # will never be called.
  #
  # @example
  #
  #  require 'oj'
  #
  #  class MySaj < ::Oj::Saj
  #    def initialize()
  #      @hash_cnt = 0
  #    end
  #
  #    def hash_start(key)
  #      @hash_cnt += 1
  #    end
  #  end
  #
  #  cnt = MySaj.new()
  #  File.open('any.json', 'r') do |f|
  #    Oj.saj_parse(cnt, f)
  #  end
  #
  # or
  #
  #  p = Oj::Parser.new(:saj)
  #  p.handler = MySaj.new()
  #  File.open('any.json', 'r') do |f|
  #    p.parse(f.read)
  #  end
  #
  # To make the desired methods active while parsing the desired method should
  # be made public in the subclasses. If the methods remain private they will
  # not be called during parsing.
  #
  #    def hash_start(key); end
  #    def hash_end(key); end
  #    def array_start(key); end
  #    def array_end(key); end
  #    def add_value(value, key); end
  #    def error(message, line, column); end
  #
  class Saj
    # Create a new instance of the Saj handler class.
    def initialize()
    end

    # To make the desired methods active while parsing the desired method should
    # be made public in the subclasses. If the methods remain private they will
    # not be called during parsing.
    private

    def hash_start(key)
    end

    def hash_end(key)
    end

    def array_start(key)
    end

    def array_end(key)
    end

    def add_value(value, key)
    end

    def error(message, line, column)
    end

  end # Saj
end # Oj
