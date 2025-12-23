require "rspec/rails/matchers/action_cable/have_broadcasted_to"

module RSpec
  module Rails
    module Matchers
      # Namespace for various implementations of ActionCable features
      #
      # @api private
      module ActionCable
      end

      # @api public
      # Passes if a message has been sent to a stream/object inside a block.
      # May chain `at_least`, `at_most` or `exactly` to specify a number of times.
      # To specify channel from which message has been broadcasted to object use `from_channel`.
      #
      #
      # @example
      #     expect {
      #       ActionCable.server.broadcast "messages", text: 'Hi!'
      #     }.to have_broadcasted_to("messages")
      #
      #     expect {
      #       SomeChannel.broadcast_to(user)
      #     }.to have_broadcasted_to(user).from_channel(SomeChannel)
      #
      #     # Using alias
      #     expect {
      #       ActionCable.server.broadcast "messages", text: 'Hi!'
      #     }.to broadcast_to("messages")
      #
      #     expect {
      #       ActionCable.server.broadcast "messages", text: 'Hi!'
      #       ActionCable.server.broadcast "all", text: 'Hi!'
      #     }.to have_broadcasted_to("messages").exactly(:once)
      #
      #     expect {
      #       3.times { ActionCable.server.broadcast "messages", text: 'Hi!' }
      #     }.to have_broadcasted_to("messages").at_least(2).times
      #
      #     expect {
      #       ActionCable.server.broadcast "messages", text: 'Hi!'
      #     }.to have_broadcasted_to("messages").at_most(:twice)
      #
      #     expect {
      #       ActionCable.server.broadcast "messages", text: 'Hi!'
      #     }.to have_broadcasted_to("messages").with(text: 'Hi!')
      def have_broadcasted_to(target = nil)
        check_action_cable_adapter

        ActionCable::HaveBroadcastedTo.new(target, channel: described_class)
      end
      alias_method :broadcast_to, :have_broadcasted_to

    private

      # @private
      def check_action_cable_adapter
        return if ::ActionCable::SubscriptionAdapter::Test === ::ActionCable.server.pubsub

        raise StandardError, "To use ActionCable matchers set `adapter: test` in your cable.yml"
      end
    end
  end
end
