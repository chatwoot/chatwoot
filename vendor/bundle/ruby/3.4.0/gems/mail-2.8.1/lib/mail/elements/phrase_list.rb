# encoding: utf-8
# frozen_string_literal: true
require 'mail/parsers/phrase_lists_parser'
require 'mail/utilities'

module Mail
  class PhraseList #:nodoc:
    attr_reader :phrases

    def initialize(string)
      @phrases =
        if Utilities.blank? string
          []
        else
          Mail::Parsers::PhraseListsParser.parse(string).phrases.map { |p| Mail::Utilities.unquote(p) }
        end
    end
  end
end
