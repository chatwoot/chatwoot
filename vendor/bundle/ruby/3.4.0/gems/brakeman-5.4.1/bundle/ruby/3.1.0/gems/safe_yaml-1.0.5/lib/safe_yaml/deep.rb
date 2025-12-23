module SafeYAML
  class Deep
    def self.freeze(object)
      object.each do |*entry|
        value = entry.last
        case value
        when String, Regexp
          value.freeze
        when Enumerable
          Deep.freeze(value)
        end
      end

      return object.freeze
    end

    def self.copy(object)
      duplicate = object.dup rescue object

      case object
      when Array
        (0...duplicate.count).each do |i|
          duplicate[i] = Deep.copy(duplicate[i])
        end
      when Hash
        duplicate.keys.each do |key|
          duplicate[key] = Deep.copy(duplicate[key])
        end
      end

      duplicate
    end
  end
end
