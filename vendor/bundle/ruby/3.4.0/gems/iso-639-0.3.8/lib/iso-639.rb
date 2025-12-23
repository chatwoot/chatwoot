# frozen_string_literal: true

require 'csv'

class ISO_639 < Array
  # Load the ISO 639-2 dataset as an array of entries. Each entry is an array
  # with the following format:
  # * [0]: an alpha-3 (bibliographic) code
  # * [1]: an alpha-3 (terminologic) code (when given)
  # * [2]: an alpha-2 code (when given)
  # * [3]: an English name
  # * [4]: a French name of a language
  #
  # Dataset Source:
  # https://www.loc.gov/standards/iso639-2/ascii_8bits.html
  # https://www.loc.gov/standards/iso639-2/ISO-639-2_utf-8.txt
  ISO_639_2 = lambda do
    dataset = []

    File.open(
      File.join(File.dirname(__FILE__), 'data', 'ISO-639-2_utf-8.txt'),
      'r:bom|utf-8'
    ) do |file|
      CSV.new(file, **{ col_sep: '|' }).each do |row|
        dataset << self[*row.map { |v| v || '' }].freeze
      end
    end

    dataset
  end.call.freeze

  # An inverted index generated from the ISO_639_2 data. Used for searching
  # all words and codes in all fields.
  INVERTED_INDEX = lambda do
    index = {}

    ISO_639_2.each_with_index do |record, i|
      record.each do |field|
        downcased = field.downcase

        words = (
          downcased.split(/[[:blank:]]|\(|\)|,|;/) +
          downcased.split(/;/)
        )

        words.each do |word|
          unless word.empty?
            index[word] ||= []
            index[word] <<  i
          end
        end
      end
    end

    index
  end.call.freeze

  # The ISO 639-1 dataset as an array of entries. Each entry is an array with
  # the following format:
  # * [0]: an ISO 369-2 alpha-3 (bibliographic) code
  # * [1]: an ISO 369-2 alpha-3 (terminologic) code (when given)
  # * [2]: an ISO 369-1 alpha-2 code (when given)
  # * [3]: an English name
  # * [4]: a French name
  ISO_639_1 = ISO_639_2.collect do |entry|
    entry unless entry[2].empty?
  end.compact.freeze

  class << self
    # Returns the entry array for an alpha-2 or alpha-3 code
    def find_by_code(code)
      return if code.nil?

      case code.length
      when 3, 7
        ISO_639_2.detect do |entry|
          entry if [entry.alpha3, entry.alpha3_terminologic].include?(code)
        end
      when 2
        ISO_639_1.detect do |entry|
          entry if entry.alpha2 == code
        end
      end
    end

    alias_method :find, :find_by_code

    # Returns the entry array for a language specified by its English name.
    def find_by_english_name(name)
      ISO_639_2.detect do |entry|
        entry if entry.english_name == name
      end
    end

    # Returns the entry array for a language specified by its French name.
    def find_by_french_name(name)
      ISO_639_2.detect do |entry|
        entry if entry.french_name == name
      end
    end

    # Returns an array of matches for the search term. The term can be a code
    # of any kind, or it can be one of the words contained in the English or
    # French name field.
    def search(term)
      term            ||= ''

      normalized_term = term.downcase.strip
      indexes         = INVERTED_INDEX[normalized_term]

      indexes ? ISO_639_2.values_at(*indexes).uniq : []
    end
  end

  # The entry's alpha-3 bibliotigraphic code.
  def alpha3_bibliographic
    self[0]
  end

  alias_method :alpha3, :alpha3_bibliographic

  # The entry's alpha-3 terminologic (when given)
  def alpha3_terminologic
    self[1]
  end

  # The entry's alpha-2 code (when given)
  def alpha2
    self[2]
  end

  # The entry's english name.
  def english_name
    self[3]
  end

  # The entry's french name.
  def french_name
    self[4]
  end
end
