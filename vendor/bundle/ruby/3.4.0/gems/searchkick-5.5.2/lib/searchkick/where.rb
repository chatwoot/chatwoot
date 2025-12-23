module Searchkick
  class Where
    def initialize(relation)
      @relation = relation
    end

    def not(value)
      @relation.where(_not: value)
    end
  end
end
