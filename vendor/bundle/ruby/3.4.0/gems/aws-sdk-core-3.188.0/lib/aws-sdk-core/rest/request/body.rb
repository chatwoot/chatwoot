# frozen_string_literal: true

module Aws
  module Rest
    module Request
      class Body

        include Seahorse::Model::Shapes

        # @param [Class] serializer_class
        # @param [Seahorse::Model::ShapeRef] rules
        def initialize(serializer_class, rules)
          @serializer_class = serializer_class
          @rules = rules
        end

        # @param [Seahorse::Client::Http::Request] http_req
        # @param [Hash] params
        def apply(http_req, params)
          body = build_body(params)
          # for rest-json, ensure we send at least an empty object
          # don't send an empty object for streaming? case.
          if body.nil? && @serializer_class == Json::Builder &&
             modeled_body? && !streaming?
            body = '{}'
          end
          http_req.body = body
        end

        private

        # operation is modeled for body when it is modeled for a payload
        # either with payload trait or normal members.
        def modeled_body?
          return true if @rules[:payload]
          @rules.shape.members.each do |member|
            _name, shape = member
            return true if shape.location.nil?
          end
          false
        end

        def build_body(params)
          if streaming?
            params[@rules[:payload]]
          elsif @rules[:payload]
            params = params[@rules[:payload]]
            serialize(@rules[:payload_member], params) if params
          else
            params = body_params(params)
            serialize(@rules, params) unless params.empty?
          end
        end

        def streaming?
          @rules[:payload] && (
            BlobShape === @rules[:payload_member].shape ||
            StringShape === @rules[:payload_member].shape
          )
        end

        def serialize(rules, params)
          @serializer_class.new(rules).serialize(params)
        end

        def body_params(params)
          @rules.shape.members.inject({}) do |hash, (member_name, member_ref)|
            if !member_ref.location && params.key?(member_name)
              hash[member_name] = params[member_name]
            end
            hash
          end
        end

      end
    end
  end
end
