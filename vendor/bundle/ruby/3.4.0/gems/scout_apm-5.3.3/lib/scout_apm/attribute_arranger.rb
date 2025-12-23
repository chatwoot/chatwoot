module ScoutApm
  module AttributeArranger
    # pass in an array of symbols to return as hash keys
    # if the symbol doesn't match the name of the method, pass an array: [:key, :method_name]
    def self.call(subject, attributes_list)
      attributes_list.inject({}) do |attribute_hash, attribute|
        case attribute
        when Array
          attribute_hash[attribute[0]] = subject.send(attribute[1])
        when :bucket
          attribute_hash[attribute] = subject.bucket_type
        when :name
          attribute_hash[attribute] = subject.bucket_name
        when Symbol
          data = subject.send(attribute)

          # Never try to `as_json` a time object, since it'll break if the
          # app has the Oj gem set to mimic_JSON, and there's never
          # anything interesting nested inside of a Time obj. We just want
          # the ISO8601 string (which happens later in the payload
          # serializing process)
          if data.is_a?(Time)
            attribute_hash[attribute] = data
          elsif data.respond_to?(:as_json)
            attribute_hash[attribute] = data.as_json
          else
            attribute_hash[attribute] = data
          end
        end
        attribute_hash
      end
    end
  end
end
