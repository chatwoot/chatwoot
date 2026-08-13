class Captain::Routines::Operations::Query < Captain::Routines::Operations::Base
  class << self
    attr_reader :return_type

    def returns(type)
      @return_type = type.to_s
    end

    def definition
      super.merge(returns: return_type)
    end
  end

  def self.kind
    'query'
  end
end
