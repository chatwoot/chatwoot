# frozen_string_literal: true

module Nokogiri
  module Gumbo
    # The default maximum number of attributes per element.
    DEFAULT_MAX_ATTRIBUTES = 400

    # The default maximum number of errors for parsing a document or a fragment.
    DEFAULT_MAX_ERRORS = 0

    # The default maximum depth of the DOM tree produced by parsing a document
    # or fragment.
    DEFAULT_MAX_TREE_DEPTH = 400
  end
end
