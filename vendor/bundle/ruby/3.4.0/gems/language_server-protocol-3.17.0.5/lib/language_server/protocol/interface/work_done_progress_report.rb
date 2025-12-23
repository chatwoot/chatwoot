module LanguageServer
  module Protocol
    module Interface
      class WorkDoneProgressReport
        def initialize(kind:, cancellable: nil, message: nil, percentage: nil)
          @attributes = {}

          @attributes[:kind] = kind
          @attributes[:cancellable] = cancellable if cancellable
          @attributes[:message] = message if message
          @attributes[:percentage] = percentage if percentage

          @attributes.freeze
        end

        # @return ["report"]
        def kind
          attributes.fetch(:kind)
        end

        #
        # Controls enablement state of a cancel button. This property is only valid
        # if a cancel button got requested in the `WorkDoneProgressBegin` payload.
        #
        # Clients that don't support cancellation or don't support control the
        # button's enablement state are allowed to ignore the setting.
        #
        # @return [boolean]
        def cancellable
          attributes.fetch(:cancellable)
        end

        #
        # Optional, more detailed associated progress message. Contains
        # complementary information to the `title`.
        #
        # Examples: "3/25 files", "project/src/module2", "node_modules/some_dep".
        # If unset, the previous progress message (if any) is still valid.
        #
        # @return [string]
        def message
          attributes.fetch(:message)
        end

        #
        # Optional progress percentage to display (value 100 is considered 100%).
        # If not provided infinite progress is assumed and clients are allowed
        # to ignore the `percentage` value in subsequent in report notifications.
        #
        # The value should be steadily rising. Clients are free to ignore values
        # that are not following this rule. The value range is [0, 100]
        #
        # @return [number]
        def percentage
          attributes.fetch(:percentage)
        end

        attr_reader :attributes

        def to_hash
          attributes
        end

        def to_json(*args)
          to_hash.to_json(*args)
        end
      end
    end
  end
end
