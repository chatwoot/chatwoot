module Regexp::Expression
  class Root < Regexp::Expression::Subexpression
    def self.build(options = {})
      warn "`#{self.class}.build(options)` is deprecated and will raise in "\
           "regexp_parser v3.0.0. Please use `.construct(options: options)`."
      construct(options: options)
    end
  end
end
