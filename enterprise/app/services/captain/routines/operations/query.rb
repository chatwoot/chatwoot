class Captain::Routines::Operations::Query < Captain::Routines::Operations::Base
  class << self
    attr_reader :return_type, :return_entity

    def returns(type, of:)
      @return_type = type.to_s
      @return_entity = of.to_s
    end

    def definition
      super.merge(returns: return_type, entity: return_entity)
    end
  end

  def self.kind
    'query'
  end
end
