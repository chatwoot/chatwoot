# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Treasury
    class ReceivedCreditListParams < ::Stripe::RequestParams
      class LinkedFlows < ::Stripe::RequestParams
        # The source flow type.
        attr_accessor :source_flow_type

        def initialize(source_flow_type: nil)
          @source_flow_type = source_flow_type
        end
      end
      # A cursor for use in pagination. `ending_before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with `obj_bar`, your subsequent call can include `ending_before=obj_bar` in order to fetch the previous page of the list.
      attr_accessor :ending_before
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # The FinancialAccount that received the funds.
      attr_accessor :financial_account
      # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
      attr_accessor :limit
      # Only return ReceivedCredits described by the flow.
      attr_accessor :linked_flows
      # A cursor for use in pagination. `starting_after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with `obj_foo`, your subsequent call can include `starting_after=obj_foo` in order to fetch the next page of the list.
      attr_accessor :starting_after
      # Only return ReceivedCredits that have the given status: `succeeded` or `failed`.
      attr_accessor :status

      def initialize(
        ending_before: nil,
        expand: nil,
        financial_account: nil,
        limit: nil,
        linked_flows: nil,
        starting_after: nil,
        status: nil
      )
        @ending_before = ending_before
        @expand = expand
        @financial_account = financial_account
        @limit = limit
        @linked_flows = linked_flows
        @starting_after = starting_after
        @status = status
      end
    end
  end
end
