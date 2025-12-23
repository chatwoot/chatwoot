# frozen_string_literal: true

# Extensions to the core String class
class String
  unless method_defined?(:blank?) && ' '.blank?
    # Checks whether a string is blank. A string is considered blank if it
    # is either empty or contains only whitespace characters.
    #
    # @return [Boolean] true is the string is blank, false otherwise
    #
    # @example
    #   ''.blank?       #=> true
    #   '    '.blank?   #=> true
    #   '  test'.blank? #=> false
    def blank?
      empty? || lstrip.empty?
    end
  end
end
