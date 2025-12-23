module TelephoneNumber
  class Formatter

    attr_reader :normalized_number, :country, :valid, :original_number

    def initialize(number_obj)
      @normalized_number = number_obj.normalized_number
      @country = number_obj.country
      @valid = number_obj.valid?
      @original_number = number_obj.original_number
    end

    def national_number(formatted: true)
      return original_or_default if !valid? || !number_format
      build_national_number(formatted: formatted)
    end

    def e164_number(formatted: true)
      return original_or_default if !valid?
      build_e164_number(formatted: formatted)
    end

    def international_number(formatted: true)
      return original_or_default if !valid? || !number_format
      build_international_number(formatted: formatted)
    end

    alias_method :valid?, :valid

    private

    def number_format
      @number_format ||= country.detect_format(normalized_number)
    end

    def build_national_number(formatted: true)
      national_prefix_formatting_rule = number_format.national_prefix_formatting_rule
      formatted_number = if national_prefix_formatting_rule
        national_prefix_formatting_rule = national_prefix_formatting_rule.sub(/\$NP/, country.national_prefix.to_s).sub(/\$FG/, '\\\1')
        format = number_format.format.sub(/(\$\d)/, national_prefix_formatting_rule).gsub(/\$/, '\\\\')
        normalized_number.sub(number_format.pattern, format)
      else
        normalized_number.sub(number_format.pattern, number_format.format.gsub(/\$/, '\\\\'))
      end
      formatted ? formatted_number : TelephoneNumber.sanitize(formatted_number)
    end

    def build_e164_number(formatted: true)
      formatted_string = "+#{country.country_code}#{normalized_number}"
      formatted ? formatted_string : TelephoneNumber.sanitize(formatted_string)
    end

    def build_international_number(formatted: true)
      return original_or_default if !valid? || number_format.nil?
      format_to_use = number_format.intl_format || number_format.format
      formatted_string = normalized_number.sub(number_format.pattern, format_to_use.gsub(/\$/, '\\\\'))
      formatted_string = "+#{country.country_code} #{formatted_string}"
      formatted ? formatted_string : TelephoneNumber.sanitize(formatted_string)
    end

    def ruby_format_string(format_string)
      format_string.gsub(/(\$\d)/) { |cap| "%#{cap.reverse}s" }
    end

    def original_or_default
      return original_number unless TelephoneNumber.default_format_string && TelephoneNumber.default_format_pattern
      captures = original_number.match(TelephoneNumber.default_format_pattern).captures
      format(ruby_format_string(TelephoneNumber.default_format_string), *captures)
    end
  end
end
