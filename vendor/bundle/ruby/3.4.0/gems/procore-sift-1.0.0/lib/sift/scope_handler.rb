module Sift
  class ScopeHandler
    def initialize(param)
      @param = param
    end

    def call(collection, value, params, scope_params)
      collection.public_send(@param.internal_name, *scope_parameters(value, params, scope_params))
    end

    def scope_parameters(value, params, scope_params)
      if scope_params.empty?
        [value]
      else
        [value, mapped_scope_params(params, scope_params)]
      end
    end

    def mapped_scope_params(params, scope_params)
      scope_params.each_with_object({}) do |scope_param, hash|
        hash[scope_param] = params.fetch(scope_param)
      end
    end
  end
end
