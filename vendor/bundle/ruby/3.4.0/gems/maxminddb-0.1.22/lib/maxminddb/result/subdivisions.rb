module MaxMindDB
  class Result
    class Subdivisions < Array
      def initialize(raw)
        super((raw || []).map { |hash| NamedLocation.new(hash) })
      end

      def most_specific
        last || NamedLocation.new({})
      end

      def inspect
        "#<MaxMindDB::Result::Subdivisions: #{super}>"
      end
    end
  end
end
