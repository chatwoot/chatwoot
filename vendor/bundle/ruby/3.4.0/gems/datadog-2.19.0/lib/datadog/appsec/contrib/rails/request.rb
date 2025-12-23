# frozen_string_literal: true

module Datadog
  module AppSec
    module Contrib
      module Rails
        # Normalized extration of data from ActionDispatch::Request
        module Request
          def self.parsed_body(request)
            # force body parameter parsing, which is done lazily by Rails
            request.parameters

            # usually Hash<String,String> but can be a more complex
            # Hash<String,String||Array||Hash> when e.g coming from JSON or
            # with Rails advanced param square bracket parsing
            body = request.env['action_dispatch.request.request_parameters']

            return if body.nil?

            body.reject do |k, _v|
              request.env['action_dispatch.request.path_parameters'].key?(k)
            end
          end

          def self.route_params(request)
            excluded = [:controller, :action]

            request.env['action_dispatch.request.path_parameters'].reject do |k, _v|
              excluded.include?(k)
            end
          end
        end
      end
    end
  end
end
