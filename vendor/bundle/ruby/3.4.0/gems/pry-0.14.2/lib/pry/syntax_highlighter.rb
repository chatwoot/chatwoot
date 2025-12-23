# frozen_string_literal: true

require 'coderay'

class Pry
  # @api private
  # @since v0.13.0
  class SyntaxHighlighter
    def self.highlight(code, language = :ruby)
      tokenize(code, language).term
    end

    def self.tokenize(code, language = :ruby)
      CodeRay.scan(code, language)
    end

    def self.keyword_token_color
      CodeRay::Encoders::Terminal::TOKEN_COLORS[:keyword]
    end

    # Sets comment token to blue (black by default), so it's more legible.
    def self.overwrite_coderay_comment_token!
      CodeRay::Encoders::Terminal::TOKEN_COLORS[:comment][:self] = "\e[1;34m"
    end
  end
end
