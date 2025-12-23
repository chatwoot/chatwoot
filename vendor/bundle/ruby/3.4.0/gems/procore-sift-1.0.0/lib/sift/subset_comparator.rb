module Sift
  class SubsetComparator
    def initialize(array)
      @array = array
    end

    def include?(other)
      other = [other] unless other.is_a?(Array)

      @array.to_set >= other.to_set
    end
  end
end
