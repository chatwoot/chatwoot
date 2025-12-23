# frozen_string_literal: true

module OAuth
  class Problem < OAuth::Unauthorized
    attr_reader :problem, :params

    def initialize(problem, request = nil, params = {})
      super(request)
      @problem = problem
      @params  = params
    end

    def to_s
      problem
    end
  end
end
