# frozen_string_literal: true

module MyinvestChatImport
  module CanonicalJson
    module_function

    def dump(value)
      JSON.generate(sort(value))
    end

    def sort(value)
      case value
      when Hash
        value.keys.sort.to_h { |key| [key, sort(value.fetch(key))] }
      when Array
        value.map { |item| sort(item) }
      else
        value
      end
    end
  end
end
