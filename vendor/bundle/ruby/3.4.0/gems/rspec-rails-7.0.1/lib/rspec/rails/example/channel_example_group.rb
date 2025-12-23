require "rspec/rails/matchers/action_cable/have_streams"

module RSpec
  module Rails
    # @api public
    # Container module for channel spec functionality. It is only available if
    # ActionCable has been loaded before it.
    module ChannelExampleGroup
      # @private
      module ClassMethods
        # These blank modules are only necessary for YARD processing. It doesn't
        # handle the conditional check below very well and reports undocumented objects.
      end
    end
  end
end

if RSpec::Rails::FeatureCheck.has_action_cable_testing?
  module RSpec
    module Rails
      # @api public
      # Container module for channel spec functionality.
      module ChannelExampleGroup
        extend ActiveSupport::Concern
        include RSpec::Rails::RailsExampleGroup
        include ActionCable::Connection::TestCase::Behavior
        include ActionCable::Channel::TestCase::Behavior

        # Class-level DSL for channel specs.
        module ClassMethods
          # @private
          def channel_class
            (_channel_class || described_class).tap do |klass|
              next if klass <= ::ActionCable::Channel::Base

              raise "Described class is not a channel class.\n" \
                    "Specify the channel class in the `describe` statement " \
                    "or set it manually using `tests MyChannelClass`"
            end
          end

          # @private
          def connection_class
            (_connection_class || described_class).tap do |klass|
              next if klass <= ::ActionCable::Connection::Base

              raise "Described class is not a connection class.\n" \
                    "Specify the connection class in the `describe` statement " \
                    "or set it manually using `tests MyConnectionClass`"
            end
          end
        end

        # Checks that the connection attempt has been rejected.
        #
        # @example
        #     expect { connect }.to have_rejected_connection
        def have_rejected_connection
          raise_error(::ActionCable::Connection::Authorization::UnauthorizedError)
        end

        # Checks that the subscription is subscribed to at least one stream.
        #
        # @example
        #     expect(subscription).to have_streams
        def have_streams
          check_subscribed!

          RSpec::Rails::Matchers::ActionCable::HaveStream.new
        end

        # Checks that the channel has been subscribed to the given stream
        #
        # @example
        #     expect(subscription).to have_stream_from("chat_1")
        def have_stream_from(stream)
          check_subscribed!

          RSpec::Rails::Matchers::ActionCable::HaveStream.new(stream)
        end

        # Checks that the channel has been subscribed to a stream for the given model
        #
        # @example
        #     expect(subscription).to have_stream_for(user)
        def have_stream_for(object)
          check_subscribed!
          RSpec::Rails::Matchers::ActionCable::HaveStream.new(broadcasting_for(object))
        end
      end
    end
  end
end
