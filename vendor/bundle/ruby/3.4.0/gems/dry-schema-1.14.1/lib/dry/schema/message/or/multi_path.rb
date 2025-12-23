# frozen_string_literal: true

module Dry
  module Schema
    class Message
      module Or
        # A message type used by OR operations with different paths
        #
        # @api public
        class MultiPath < Abstract
          # @api private
          class MessageArray
            # @api private
            def initialize(messages)
              @messages = messages.flatten
            end

            # @api private
            def _paths
              @messages.map(&:_path)
            end

            # @api private
            def to_or(root)
              self.class.new(@messages.map { _1.to_or(root) })
            end

            # @api private
            def to_h
              MessageSet.new(@messages).to_h
            end
          end

          MESSAGE_ARRAY_HANDLER = -> { MessageArray.new(_1) }

          # @api private
          def self.handler(message)
            case message
            when self
              IDENTITY
            when Array
              MESSAGE_ARRAY_HANDLER
            end
          end

          # @api public
          def to_h
            @to_h ||= Path[[*root, :or]].to_h(messages.map(&:to_h))
          end

          # @api private
          def messages
            @messages ||= _messages.flat_map { _1.to_or(root) }
          end

          # @api private
          def root
            @root ||= _paths.reduce(:&)
          end

          # @api private
          def path
            root
          end

          # @api private
          def _path
            @_path ||= Path[root]
          end

          # @api private
          def _paths
            @paths ||= _messages.flat_map(&:_paths)
          end

          # @api private
          def to_or(root)
            self.root == root ? messages : [self]
          end

          private

          # @api private
          def _messages
            @_messages ||= [left, right].map do |message|
              handler = self.class.handler(message)

              unless handler
                raise ArgumentError,
                      "#{message.inspect} is of unknown type #{message.class.inspect}"
              end

              handler.(message)
            end
          end
        end
      end
    end
  end
end
