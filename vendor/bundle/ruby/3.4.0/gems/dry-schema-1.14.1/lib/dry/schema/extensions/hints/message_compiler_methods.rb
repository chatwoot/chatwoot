# frozen_string_literal: true

module Dry
  module Schema
    module Extensions
      module Hints
        # Adds support for processing [:hint, ...] nodes produced by dry-logic
        #
        # @api private
        module MessageCompilerMethods
          HINT_TYPE_EXCLUSION = %i[
            key? nil? bool? str? int? float? decimal?
            date? date_time? time? hash? array?
          ].freeze

          HINT_OTHER_EXCLUSION = %i[format? filled?].freeze

          # @api private
          attr_reader :hints

          # @api private
          def initialize(*, **)
            super
            @hints = @options.fetch(:hints, true)
          end

          # @api private
          def hints?
            hints.equal?(true)
          end

          # @api private
          def filter(messages, opts)
            Array(messages).flatten.reject { |msg| exclude?(msg, opts) }.uniq
          end

          # @api private
          # rubocop: disable Metrics/AbcSize
          # rubocop: disable Metrics/PerceivedComplexity
          # rubocop: disable Metrics/CyclomaticComplexity
          def exclude?(messages, opts)
            Array(messages).all? do |msg|
              hints = opts.hints.reject { |h|
                msg.eql?(h) || h.predicate.eql?(:filled?)
              }

              key_failure = opts.key_failure?(msg.path)
              predicate = msg.predicate

              (HINT_TYPE_EXCLUSION.include?(predicate) && !key_failure) ||
                (msg.predicate == :filled? && key_failure) ||
                (!key_failure && HINT_TYPE_EXCLUSION.include?(predicate) &&
                  !hints.empty? && hints.any? { |hint| hint.path == msg.path }) ||
                HINT_OTHER_EXCLUSION.include?(predicate)
            end
          end
          # rubocop: enable Metrics/CyclomaticComplexity
          # rubocop: enable Metrics/PerceivedComplexity
          # rubocop: enable Metrics/AbcSize

          # @api private
          def message_type(options)
            options[:message_type].equal?(:hint) ? Hint : Message
          end

          # @api private
          def visit_hint(node, opts)
            if hints?
              filter(visit(node, opts.(message_type: :hint)), opts)
            end
          end

          # @api private
          def visit_predicate(node, opts)
            message = super
            opts.current_messages << message
            message
          end

          # @api private
          def visit_each(_node, _opts)
            # TODO: we can still generate a hint for elements here!
            []
          end
        end
      end
    end
  end
end
