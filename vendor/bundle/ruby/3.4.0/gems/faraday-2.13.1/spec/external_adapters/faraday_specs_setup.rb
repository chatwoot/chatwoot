# frozen_string_literal: true

require 'webmock/rspec'
WebMock.disable_net_connect!(allow_localhost: true)

require_relative '../support/helper_methods'
require_relative '../support/disabling_stub'
require_relative '../support/streaming_response_checker'
require_relative '../support/shared_examples/adapter'
require_relative '../support/shared_examples/request_method'

RSpec.configure do |config|
  config.include Faraday::HelperMethods
end
