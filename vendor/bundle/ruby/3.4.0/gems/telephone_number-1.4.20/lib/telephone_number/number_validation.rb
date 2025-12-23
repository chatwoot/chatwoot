module TelephoneNumber
  class NumberValidation
    attr_reader :name, :pattern

    def initialize(name, data_hash)
      @name = name
      @pattern = data_hash[:national_number_pattern]
    end
  end
end
