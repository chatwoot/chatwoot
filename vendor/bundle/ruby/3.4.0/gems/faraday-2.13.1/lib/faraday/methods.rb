# frozen_string_literal: true

module Faraday
  METHODS_WITH_QUERY = %w[get head delete trace].freeze
  METHODS_WITH_BODY = %w[post put patch].freeze
end
