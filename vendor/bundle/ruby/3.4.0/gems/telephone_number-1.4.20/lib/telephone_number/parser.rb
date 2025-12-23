module TelephoneNumber
  class Parser
    attr_reader :original_number, :normalized_number, :country

    def initialize(number_obj)
      @original_number = number_obj.original_number
      @country = number_obj.country
      @normalized_number = build_normalized_number if @country
    end

    def valid_types
      @valid_types ||= generate_valid_types(normalized_number)
    end

    def valid?(keys = [])
      keys.empty? ? !valid_types.empty? : !(valid_types & keys.map(&:to_sym)).empty?
    end

    private

    # normalized_number is basically a "best effort" at national number without
    # any formatting. This is what we will use to derive formats, validations and
    # basically anything else that uses google data
    def build_normalized_number
      match_result = parse_prefix.match(country.full_general_pattern)

      if match_result && generate_valid_types(match_result[:national_num]).any?
        match_result[:national_num]
      else
        original_number
      end
    end

    # returns an array of valid types for the given number
    # if array is empty, we can assume that the number is invalid
    def generate_valid_types(number)
      return [] unless country
      country.validations.select do |validation|
        number.match?(Regexp.new("^(#{validation.pattern})$"))
      end.map(&:name)
    end

    def parse_prefix
      return original_number unless country.national_prefix_for_parsing
      duped = original_number.dup
      match_object = duped.match("^(?:#{country.national_prefix_for_parsing})")

      # we need to do the "start_with?" here because we need to make sure it's not finding
      # something in the middle of the number. However, we can't modify the regex to do this
      # for us because it will offset the match groups that are referenced in the transform rules
      return original_number unless match_object && duped.start_with?(match_object[0])
      if country.national_prefix_transform_rule
        transform_national_prefix(duped, match_object)
      else
        duped.sub!(match_object[0], '')
      end
    end

    def transform_national_prefix(duped, match_object)
      if country.mobile_token && match_object.captures.any?
        format(build_format_string, duped.sub!(match_object[0], match_object[1]))
      elsif match_object.captures.none?
        duped.sub!(match_object[0], '')
      else
        format(build_format_string, *match_object.captures)
      end
    end

    def build_format_string
      country.national_prefix_transform_rule.gsub(/(\$\d)/) { |cap| "%#{cap.reverse}s" }
    end
  end
end
