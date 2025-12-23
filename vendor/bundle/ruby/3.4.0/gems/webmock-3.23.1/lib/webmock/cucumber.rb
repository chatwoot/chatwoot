# frozen_string_literal: true

require 'webmock'
require 'webmock/rspec/matchers'

WebMock.enable!

World(WebMock::API, WebMock::Matchers)

After do
  WebMock.reset!
end
