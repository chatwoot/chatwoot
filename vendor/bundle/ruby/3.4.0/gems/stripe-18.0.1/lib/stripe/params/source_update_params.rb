# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class SourceUpdateParams < ::Stripe::RequestParams
    class Mandate < ::Stripe::RequestParams
      class Acceptance < ::Stripe::RequestParams
        class Offline < ::Stripe::RequestParams
          # An email to contact you with if a copy of the mandate is requested, required if `type` is `offline`.
          attr_accessor :contact_email

          def initialize(contact_email: nil)
            @contact_email = contact_email
          end
        end

        class Online < ::Stripe::RequestParams
          # The Unix timestamp (in seconds) when the mandate was accepted or refused by the customer.
          attr_accessor :date
          # The IP address from which the mandate was accepted or refused by the customer.
          attr_accessor :ip
          # The user agent of the browser from which the mandate was accepted or refused by the customer.
          attr_accessor :user_agent

          def initialize(date: nil, ip: nil, user_agent: nil)
            @date = date
            @ip = ip
            @user_agent = user_agent
          end
        end
        # The Unix timestamp (in seconds) when the mandate was accepted or refused by the customer.
        attr_accessor :date
        # The IP address from which the mandate was accepted or refused by the customer.
        attr_accessor :ip
        # The parameters required to store a mandate accepted offline. Should only be set if `mandate[type]` is `offline`
        attr_accessor :offline
        # The parameters required to store a mandate accepted online. Should only be set if `mandate[type]` is `online`
        attr_accessor :online
        # The status of the mandate acceptance. Either `accepted` (the mandate was accepted) or `refused` (the mandate was refused).
        attr_accessor :status
        # The type of acceptance information included with the mandate. Either `online` or `offline`
        attr_accessor :type
        # The user agent of the browser from which the mandate was accepted or refused by the customer.
        attr_accessor :user_agent

        def initialize(
          date: nil,
          ip: nil,
          offline: nil,
          online: nil,
          status: nil,
          type: nil,
          user_agent: nil
        )
          @date = date
          @ip = ip
          @offline = offline
          @online = online
          @status = status
          @type = type
          @user_agent = user_agent
        end
      end
      # The parameters required to notify Stripe of a mandate acceptance or refusal by the customer.
      attr_accessor :acceptance
      # The amount specified by the mandate. (Leave null for a mandate covering all amounts)
      attr_accessor :amount
      # The currency specified by the mandate. (Must match `currency` of the source)
      attr_accessor :currency
      # The interval of debits permitted by the mandate. Either `one_time` (just permitting a single debit), `scheduled` (with debits on an agreed schedule or for clearly-defined events), or `variable`(for debits with any frequency)
      attr_accessor :interval
      # The method Stripe should use to notify the customer of upcoming debit instructions and/or mandate confirmation as required by the underlying debit network. Either `email` (an email is sent directly to the customer), `manual` (a `source.mandate_notification` event is sent to your webhooks endpoint and you should handle the notification) or `none` (the underlying debit network does not require any notification).
      attr_accessor :notification_method

      def initialize(
        acceptance: nil,
        amount: nil,
        currency: nil,
        interval: nil,
        notification_method: nil
      )
        @acceptance = acceptance
        @amount = amount
        @currency = currency
        @interval = interval
        @notification_method = notification_method
      end
    end

    class Owner < ::Stripe::RequestParams
      class Address < ::Stripe::RequestParams
        # City, district, suburb, town, or village.
        attr_accessor :city
        # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
        attr_accessor :country
        # Address line 1, such as the street, PO Box, or company name.
        attr_accessor :line1
        # Address line 2, such as the apartment, suite, unit, or building.
        attr_accessor :line2
        # ZIP or postal code.
        attr_accessor :postal_code
        # State, county, province, or region.
        attr_accessor :state

        def initialize(
          city: nil,
          country: nil,
          line1: nil,
          line2: nil,
          postal_code: nil,
          state: nil
        )
          @city = city
          @country = country
          @line1 = line1
          @line2 = line2
          @postal_code = postal_code
          @state = state
        end
      end
      # Owner's address.
      attr_accessor :address
      # Owner's email address.
      attr_accessor :email
      # Owner's full name.
      attr_accessor :name
      # Owner's phone number.
      attr_accessor :phone

      def initialize(address: nil, email: nil, name: nil, phone: nil)
        @address = address
        @email = email
        @name = name
        @phone = phone
      end
    end

    class SourceOrder < ::Stripe::RequestParams
      class Item < ::Stripe::RequestParams
        # Attribute for param field amount
        attr_accessor :amount
        # Attribute for param field currency
        attr_accessor :currency
        # Attribute for param field description
        attr_accessor :description
        # The ID of the SKU being ordered.
        attr_accessor :parent
        # The quantity of this order item. When type is `sku`, this is the number of instances of the SKU to be ordered.
        attr_accessor :quantity
        # Attribute for param field type
        attr_accessor :type

        def initialize(
          amount: nil,
          currency: nil,
          description: nil,
          parent: nil,
          quantity: nil,
          type: nil
        )
          @amount = amount
          @currency = currency
          @description = description
          @parent = parent
          @quantity = quantity
          @type = type
        end
      end

      class Shipping < ::Stripe::RequestParams
        class Address < ::Stripe::RequestParams
          # City, district, suburb, town, or village.
          attr_accessor :city
          # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
          attr_accessor :country
          # Address line 1, such as the street, PO Box, or company name.
          attr_accessor :line1
          # Address line 2, such as the apartment, suite, unit, or building.
          attr_accessor :line2
          # ZIP or postal code.
          attr_accessor :postal_code
          # State, county, province, or region.
          attr_accessor :state

          def initialize(
            city: nil,
            country: nil,
            line1: nil,
            line2: nil,
            postal_code: nil,
            state: nil
          )
            @city = city
            @country = country
            @line1 = line1
            @line2 = line2
            @postal_code = postal_code
            @state = state
          end
        end
        # Shipping address.
        attr_accessor :address
        # The delivery service that shipped a physical product, such as Fedex, UPS, USPS, etc.
        attr_accessor :carrier
        # Recipient name.
        attr_accessor :name
        # Recipient phone (including extension).
        attr_accessor :phone
        # The tracking number for a physical product, obtained from the delivery service. If multiple tracking numbers were generated for this purchase, please separate them with commas.
        attr_accessor :tracking_number

        def initialize(address: nil, carrier: nil, name: nil, phone: nil, tracking_number: nil)
          @address = address
          @carrier = carrier
          @name = name
          @phone = phone
          @tracking_number = tracking_number
        end
      end
      # List of items constituting the order.
      attr_accessor :items
      # Shipping address for the order. Required if any of the SKUs are for products that have `shippable` set to true.
      attr_accessor :shipping

      def initialize(items: nil, shipping: nil)
        @items = items
        @shipping = shipping
      end
    end
    # Amount associated with the source.
    attr_accessor :amount
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Information about a mandate possibility attached to a source object (generally for bank debits) as well as its acceptance status.
    attr_accessor :mandate
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # Information about the owner of the payment instrument that may be used or required by particular source types.
    attr_accessor :owner
    # Information about the items and shipping associated with the source. Required for transactional credit (for example Klarna) sources before you can charge it.
    attr_accessor :source_order

    def initialize(
      amount: nil,
      expand: nil,
      mandate: nil,
      metadata: nil,
      owner: nil,
      source_order: nil
    )
      @amount = amount
      @expand = expand
      @mandate = mandate
      @metadata = metadata
      @owner = owner
      @source_order = source_order
    end
  end
end
