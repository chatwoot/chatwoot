# frozen_string_literal: true

module ActsAsTaggableOn
  ##
  # Returns a new TagList using the given tag string.
  #
  # Example:
  #   tag_list = ActsAsTaggableOn::DefaultParser.parse("One , Two,  Three")
  #   tag_list # ["One", "Two", "Three"]
  class DefaultParser < GenericParser
    def parse
      string = @tag_list

      string = string.join(ActsAsTaggableOn.glue) if string.respond_to?(:join)
      TagList.new.tap do |tag_list|
        string = string.to_s.dup

        string.gsub!(double_quote_pattern) do
          # Append the matched tag to the tag list
          tag_list << Regexp.last_match[2]
          # Return the matched delimiter ($3) to replace the matched items
          ''
        end

        string.gsub!(single_quote_pattern) do
          # Append the matched tag ($2) to the tag list
          tag_list << Regexp.last_match[2]
          # Return an empty string to replace the matched items
          ''
        end

        # split the string by the delimiter
        # and add to the tag_list
        tag_list.add(string.split(Regexp.new(delimiter)))
      end
    end

    # private
    def delimiter
      # Parse the quoted tags
      d = ActsAsTaggableOn.delimiter
      # Separate multiple delimiters by bitwise operator
      d = d.join('|') if d.is_a?(Array)
      d
    end

    # (             # Tag start delimiter ($1)
    # \A       |  # Either string start or
    # #{delimiter}        # a delimiter
    # )
    # \s*"          # quote (") optionally preceded by whitespace
    # (.*?)         # Tag ($2)
    # "\s*          # quote (") optionally followed by whitespace
    # (?=           # Tag end delimiter (not consumed; is zero-length lookahead)
    # #{delimiter}\s*  |  # Either a delimiter optionally followed by whitespace or
    # \z          # string end
    # )
    def double_quote_pattern
      /(\A|#{delimiter})\s*"(.*?)"\s*(?=#{delimiter}\s*|\z)/
    end

    # (             # Tag start delimiter ($1)
    # \A       |  # Either string start or
    # #{delimiter}        # a delimiter
    # )
    # \s*'          # quote (') optionally preceded by whitespace
    # (.*?)         # Tag ($2)
    # '\s*          # quote (') optionally followed by whitespace
    # (?=           # Tag end delimiter (not consumed; is zero-length lookahead)
    # #{delimiter}\s*  | d # Either a delimiter optionally followed by whitespace or
    # \z          # string end
    # )
    def single_quote_pattern
      /(\A|#{delimiter})\s*'(.*?)'\s*(?=#{delimiter}\s*|\z)/
    end
  end
end
