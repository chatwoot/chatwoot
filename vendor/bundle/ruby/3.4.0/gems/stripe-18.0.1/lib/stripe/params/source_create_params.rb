# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class SourceCreateParams < ::Stripe::RequestParams
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

    class Receiver < ::Stripe::RequestParams
      # The method Stripe should use to request information needed to process a refund or mispayment. Either `email` (an email is sent directly to the customer) or `manual` (a `source.refund_attributes_required` event is sent to your webhooks endpoint). Refer to each payment method's documentation to learn which refund attributes may be required.
      attr_accessor :refund_attributes_method

      def initialize(refund_attributes_method: nil)
        @refund_attributes_method = refund_attributes_method
      end
    end

    class Redirect < ::Stripe::RequestParams
      # The URL you provide to redirect the customer back to you after they authenticated their payment. It can use your application URI scheme in the context of a mobile application.
      attr_accessor :return_url

      def initialize(return_url: nil)
        @return_url = return_url
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
    # Amount associated with the source. This is the amount for which the source will be chargeable once ready. Required for `single_use` sources. Not supported for `receiver` type sources, where charge amount may not be specified until funds land.
    attr_accessor :amount
    # Three-letter [ISO code for the currency](https://stripe.com/docs/currencies) associated with the source. This is the currency for which the source will be chargeable once ready.
    attr_accessor :currency
    # The `Customer` to whom the original source is attached to. Must be set when the original source is not a `Source` (e.g., `Card`).
    attr_accessor :customer
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # The authentication `flow` of the source to create. `flow` is one of `redirect`, `receiver`, `code_verification`, `none`. It is generally inferred unless a type supports multiple flows.
    attr_accessor :flow
    # Information about a mandate possibility attached to a source object (generally for bank debits) as well as its acceptance status.
    attr_accessor :mandate
    # Attribute for param field metadata
    attr_accessor :metadata
    # The source to share.
    attr_accessor :original_source
    # Information about the owner of the payment instrument that may be used or required by particular source types.
    attr_accessor :owner
    # Optional parameters for the receiver flow. Can be set only if the source is a receiver (`flow` is `receiver`).
    attr_accessor :receiver
    # Parameters required for the redirect flow. Required if the source is authenticated by a redirect (`flow` is `redirect`).
    attr_accessor :redirect
    # Information about the items and shipping associated with the source. Required for transactional credit (for example Klarna) sources before you can charge it.
    attr_accessor :source_order
    # An arbitrary string to be displayed on your customer's statement. As an example, if your website is `RunClub` and the item you're charging for is a race ticket, you may want to specify a `statement_descriptor` of `RunClub 5K race ticket.` While many payment types will display this information, some may not display it at all.
    attr_accessor :statement_descriptor
    # An optional token used to create the source. When passed, token properties will override source parameters.
    attr_accessor :token
    # The `type` of the source to create. Required unless `customer` and `original_source` are specified (see the [Cloning card Sources](https://stripe.com/docs/sources/connect#cloning-card-sources) guide)
    attr_accessor :type
    # Attribute for param field usage
    attr_accessor :usage

    def initialize(
      amount: nil,
      currency: nil,
      customer: nil,
      expand: nil,
      flow: nil,
      mandate: nil,
      metadata: nil,
      original_source: nil,
      owner: nil,
      receiver: nil,
      redirect: nil,
      source_order: nil,
      statement_descriptor: nil,
      token: nil,
      type: nil,
      usage: nil
    )
      @amount = amount
      @currency = currency
      @customer = customer
      @expand = expand
      @flow = flow
      @mandate = mandate
      @metadata = metadata
      @original_source = original_source
      @owner = owner
      @receiver = receiver
      @redirect = redirect
      @source_order = source_order
      @statement_descriptor = statement_descriptor
      @token = token
      @type = type
      @usage = usage
    end
  end
end
