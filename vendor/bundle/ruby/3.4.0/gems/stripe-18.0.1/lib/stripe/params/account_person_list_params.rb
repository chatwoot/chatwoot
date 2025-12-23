# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class AccountPersonListParams < ::Stripe::RequestParams
    class Relationship < ::Stripe::RequestParams
      # A filter on the list of people returned based on whether these people are authorizers of the account's representative.
      attr_accessor :authorizer
      # A filter on the list of people returned based on whether these people are directors of the account's company.
      attr_accessor :director
      # A filter on the list of people returned based on whether these people are executives of the account's company.
      attr_accessor :executive
      # A filter on the list of people returned based on whether these people are legal guardians of the account's representative.
      attr_accessor :legal_guardian
      # A filter on the list of people returned based on whether these people are owners of the account's company.
      attr_accessor :owner
      # A filter on the list of people returned based on whether these people are the representative of the account's company.
      attr_accessor :representative

      def initialize(
        authorizer: nil,
        director: nil,
        executive: nil,
        legal_guardian: nil,
        owner: nil,
        representative: nil
      )
        @authorizer = authorizer
        @director = director
        @executive = executive
        @legal_guardian = legal_guardian
        @owner = owner
        @representative = representative
      end
    end
    # A cursor for use in pagination. `ending_before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with `obj_bar`, your subsequent call can include `ending_before=obj_bar` in order to fetch the previous page of the list.
    attr_accessor :ending_before
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
    attr_accessor :limit
    # Filters on the list of people returned based on the person's relationship to the account's company.
    attr_accessor :relationship
    # A cursor for use in pagination. `starting_after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with `obj_foo`, your subsequent call can include `starting_after=obj_foo` in order to fetch the next page of the list.
    attr_accessor :starting_after

    def initialize(
      ending_before: nil,
      expand: nil,
      limit: nil,
      relationship: nil,
      starting_after: nil
    )
      @ending_before = ending_before
      @expand = expand
      @limit = limit
      @relationship = relationship
      @starting_after = starting_after
    end
  end
end
