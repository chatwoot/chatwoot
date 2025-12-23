# frozen_string_literal: true
# typed: true

module Stripe
  # For internal use only. Does not provide a stable API and may be broken
  # with future non-major changes.
  class RequestParams
    def to_h
      instance_variables.each_with_object({}) do |var, hash|
        key = var.to_s.delete("@").to_sym
        value = instance_variable_get(var)

        hash[key] = if value.is_a?(RequestParams)
                      value.to_h
                    # Check if value is an array and contains RequestParams objects
                    elsif value.is_a?(Array)
                      value.map { |item| item.is_a?(RequestParams) ? item.to_h : item }
                    else
                      value
                    end
      end
    end
  end
end
