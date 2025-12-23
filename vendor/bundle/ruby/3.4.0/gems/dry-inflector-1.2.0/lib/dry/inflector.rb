# frozen_string_literal: true

module Dry
  # dry-inflector
  #
  # @since 0.1.0
  class Inflector
    require "dry/inflector/version"
    require "dry/inflector/inflections"

    # Instantiate the inflector
    #
    # @param blk [Proc] an optional block to specify custom inflection rules
    # @yieldparam [Dry::Inflector::Inflections] the inflection rules
    #
    # @return [Dry::Inflector] the inflector
    #
    # @since 0.1.0
    #
    # @example Basic usage
    #   require "dry/inflector"
    #
    #   inflector = Dry::Inflector.new
    #
    # @example Custom inflection rules
    #   require "dry/inflector"
    #
    #   inflector = Dry::Inflector.new do |inflections|
    #     inflections.plural      "virus",   "viruses" # specify a rule for #pluralize
    #     inflections.singular    "thieves", "thief"   # specify a rule for #singularize
    #     inflections.uncountable "dry-inflector"      # add an exception for an uncountable word
    #   end
    def initialize(&)
      @inflections = Inflections.build(&)
    end

    # Lower camelize a string
    #
    # @param input [String,Symbol] the input
    # @return [String] the lower camelized string
    #
    # @since 0.1.3
    #
    # @example
    #   require "dry/inflector"
    #
    #   inflector = Dry::Inflector.new
    #   inflector.camelize_lower("data_mapper") # => "dataMapper"
    def camelize_lower(input)
      internal_camelize(input, false)
    end

    # Upper camelize a string
    #
    # @param input [String,Symbol] the input
    # @return [String] the upper camelized string
    #
    # @since 0.1.3
    #
    # @example
    #   require "dry/inflector"
    #
    #   inflector = Dry::Inflector.new
    #   inflector.camelize_upper("data_mapper") # => "DataMapper"
    #   inflector.camelize_upper("dry/inflector") # => "Dry::Inflector"
    def camelize_upper(input)
      internal_camelize(input, true)
    end

    alias_method :camelize, :camelize_upper

    # Find a constant with the name specified in the argument string
    #
    # The name is assumed to be the one of a top-level constant,
    # constant scope of caller is ignored
    #
    # @param input [String,Symbol] the input
    # @return [Class, Module] the class or module
    #
    # @since 0.1.0
    #
    # @example
    #   require "dry/inflector"
    #
    #   inflector = Dry::Inflector.new
    #   inflector.constantize("Module")         # => Module
    #   inflector.constantize("Dry::Inflector") # => Dry::Inflector
    def constantize(input)
      Object.const_get(input, false)
    end

    # Classify a string
    #
    # @param input [String,Symbol] the input
    # @return [String] the classified string
    #
    # @since 0.1.0
    #
    # @example
    #   require "dry/inflector"
    #
    #   inflector = Dry::Inflector.new
    #   inflector.classify("books") # => "Book"
    def classify(input)
      camelize(singularize(input.to_s.split(".").last))
    end

    # Dasherize a string
    #
    # @param input [String,Symbol] the input
    # @return [String] the dasherized string
    #
    # @since 0.1.0
    #
    # @example
    #   require "dry/inflector"
    #
    #   inflector = Dry::Inflector.new
    #   inflector.dasherize("dry_inflector") # => "dry-inflector"
    def dasherize(input)
      input.to_s.tr("_", "-")
    end

    # Demodulize a string
    #
    # @param input [String,Symbol] the input
    # @return [String] the demodulized string
    #
    # @since 0.1.0
    #
    # @example
    #   require "dry/inflector"
    #
    #   inflector = Dry::Inflector.new
    #   inflector.demodulize("Dry::Inflector") # => "Inflector"
    def demodulize(input)
      input.to_s.split("::").last
    end

    # Humanize a string
    #
    # @param input [String,Symbol] the input
    # @return [String] the humanized string
    #
    # @since 0.1.0
    #
    # @example
    #   require "dry/inflector"
    #
    #   inflector = Dry::Inflector.new
    #   inflector.humanize("dry_inflector") # => "Dry inflector"
    #   inflector.humanize("author_id")     # => "Author"
    def humanize(input)
      input = input.to_s
      result = inflections.humans.apply_to(input)
      result.delete_suffix!("_id")
      result.tr!("_", " ")
      match = /(\W)/.match(result)
      separator = match ? match[0] : DEFAULT_SEPARATOR
      result.split(separator).map.with_index { |word, index|
        inflections.acronyms.apply_to(word, capitalize: index.zero?)
      }.join(separator)
    end

    # Creates a foreign key name
    #
    # @param input [String, Symbol] the input
    # @return [String] foreign key
    #
    # @example
    #   require "dry/inflector"
    #
    #   inflector = Dry::Inflector.new
    #   inflector.foreign_key("Message") => "message_id"
    def foreign_key(input)
      "#{underscore(demodulize(input))}_id"
    end

    # Ordinalize a number
    #
    # @param number [Integer] the input
    # @return [String] the ordinalized number
    #
    # @since 0.1.0
    #
    # @example
    #   require "dry/inflector"
    #
    #   inflector = Dry::Inflector.new
    #   inflector.ordinalize(1)  # => "1st"
    #   inflector.ordinalize(2)  # => "2nd"
    #   inflector.ordinalize(3)  # => "3rd"
    #   inflector.ordinalize(10) # => "10th"
    #   inflector.ordinalize(23) # => "23rd"
    def ordinalize(number)
      abs_value = number.abs

      if ORDINALIZE_TH[abs_value % 100]
        "#{number}th"
      else
        case abs_value % 10
        when 1 then "#{number}st"
        when 2 then "#{number}nd"
        when 3 then "#{number}rd"
        else        "#{number}th"
        end
      end
    end

    # Pluralize a string
    #
    # @param input [String,Symbol] the input
    # @return [String] the pluralized string
    #
    # @since 0.1.0
    #
    # @example
    #   require "dry/inflector"
    #
    #   inflector = Dry::Inflector.new
    #   inflector.pluralize("book")  # => "books"
    #   inflector.pluralize("money") # => "money"
    def pluralize(input)
      input = input.to_s
      return input if uncountable?(input)

      inflections.plurals.apply_to(input)
    end

    # Singularize a string
    #
    # @param input [String] the input
    # @return [String] the singularized string
    #
    # @since 0.1.0
    #
    # @example
    #   require "dry/inflector"
    #
    #   inflector = Dry::Inflector.new
    #   inflector.singularize("books") # => "book"
    #   inflector.singularize("money") # => "money"
    def singularize(input)
      input = input.to_s
      return input if uncountable?(input)

      inflections.singulars.apply_to(input)
    end

    # Tableize a string
    #
    # @param input [String,Symbol] the input
    # @return [String] the tableized string
    #
    # @since 0.1.0
    #
    # @example
    #   require "dry/inflector"
    #
    #   inflector = Dry::Inflector.new
    #   inflector.tableize("Book") # => "books"
    def tableize(input)
      input = input.to_s.gsub("::", "_")
      pluralize(underscore(input))
    end

    # Underscore a string
    #
    # @param input [String,Symbol] the input
    # @return [String] the underscored string
    #
    # @since 0.1.0
    #
    # @example
    #   require "dry/inflector"
    #
    #   inflector = Dry::Inflector.new
    #   inflector.underscore("dry-inflector") # => "dry_inflector"
    def underscore(input)
      input = input.to_s.gsub("::", "/")
      input.gsub!(inflections.acronyms.regex) do
        m1 = Regexp.last_match(1)
        m2 = Regexp.last_match(2)
        "#{m1 ? "_" : ""}#{m2.downcase}"
      end
      input.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
      input.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
      input.tr!("-", "_")
      input.downcase!
      input
    end

    # Check if the input is an uncountable word
    #
    # @param input [String] the input
    # @return [TrueClass,FalseClass] the result of the check
    #
    # @since 0.1.0
    # @api private
    def uncountable?(input)
      input.match?(/\A[[:space:]]*\z/) ||
        inflections.uncountables.include?(input.downcase) ||
        inflections.uncountables.include?(input.split(/_|\b/).last.downcase)
    end

    # @return [String]
    #
    # @since 0.2.0
    # @api public
    def to_s
      "#<Dry::Inflector>"
    end
    alias_method :inspect, :to_s

    private

    # @since 0.1.0
    # @api private
    ORDINALIZE_TH = {11 => true, 12 => true, 13 => true}.freeze

    # @since 0.1.2
    # @api private
    DEFAULT_SEPARATOR = " "

    attr_reader :inflections

    # @since 0.1.3
    # @api private
    def internal_camelize(input, upper)
      input = input.to_s.dup
      input.sub!(/^[a-z\d]*/) { |match| inflections.acronyms.apply_to(match, capitalize: upper) }
      input.gsub!(%r{(?:[_-]|(/))([a-z\d]*)}i) do
        m1 = Regexp.last_match(1)
        m2 = Regexp.last_match(2)
        "#{m1}#{inflections.acronyms.apply_to(m2)}"
      end
      input.gsub!("/", "::")
      input
    end
  end
end
