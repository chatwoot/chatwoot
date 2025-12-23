module TelephoneNumber
  module ClassMethods
    attr_accessor :override_file, :default_format_string
    attr_reader :default_format_pattern

    def default_format_pattern=(format_string)
      @default_format_pattern = Regexp.new(format_string)
    end

    def parse(number, country = nil)
      TelephoneNumber::Number.new(number, country)
    end

    def valid?(number, country = nil, keys = [])
      parse(number, country).valid?(keys)
    end

    def invalid?(*args)
      !valid?(*args)
    end

    def sanitize(input_number)
      input_number.to_s.gsub(/\D/, '')
    end

    # generates binary file from xml that user gives us
    def generate_override_file(file)
      PhoneDataImporter.new(file, override: true).import!
    end
  end
end
