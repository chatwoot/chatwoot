# frozen_string_literal: true

require_relative "../syntax_error"
module Nokogiri
  module CSS
    class SyntaxError < ::Nokogiri::SyntaxError
    end
  end
end
