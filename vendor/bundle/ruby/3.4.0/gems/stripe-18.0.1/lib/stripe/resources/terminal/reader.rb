# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Terminal
    # A Reader represents a physical device for accepting payment details.
    #
    # Related guide: [Connecting to a reader](https://stripe.com/docs/terminal/payments/connect-reader)
    class Reader < APIResource
      extend Stripe::APIOperations::Create
      include Stripe::APIOperations::Delete
      extend Stripe::APIOperations::List
      include Stripe::APIOperations::Save

      OBJECT_NAME = "terminal.reader"
      def self.object_name
        "terminal.reader"
      end

      class Action < ::Stripe::StripeObject
        class CollectInputs < ::Stripe::StripeObject
          class Input < ::Stripe::StripeObject
            class CustomText < ::Stripe::StripeObject
              # Customize the default description for this input
              attr_reader :description
              # Customize the default label for this input's skip button
              attr_reader :skip_button
              # Customize the default label for this input's submit button
              attr_reader :submit_button
              # Customize the default title for this input
              attr_reader :title

              def self.inner_class_types
                @inner_class_types = {}
              end

              def self.field_remappings
                @field_remappings = {}
              end
            end

            class Email < ::Stripe::StripeObject
              # The collected email address
              attr_reader :value

              def self.inner_class_types
                @inner_class_types = {}
              end

              def self.field_remappings
                @field_remappings = {}
              end
            end

            class Numeric < ::Stripe::StripeObject
              # The collected number
              attr_reader :value

              def self.inner_class_types
                @inner_class_types = {}
              end

              def self.field_remappings
                @field_remappings = {}
              end
            end

            class Phone < ::Stripe::StripeObject
              # The collected phone number
              attr_reader :value

              def self.inner_class_types
                @inner_class_types = {}
              end

              def self.field_remappings
                @field_remappings = {}
              end
            end

            class Selection < ::Stripe::StripeObject
              class Choice < ::Stripe::StripeObject
                # The identifier for the selected choice. Maximum 50 characters.
                attr_reader :id
                # The button style for the choice. Can be `primary` or `secondary`.
                attr_reader :style
                # The text to be selected. Maximum 30 characters.
                attr_reader :text

                def self.inner_class_types
                  @inner_class_types = {}
                end

                def self.field_remappings
                  @field_remappings = {}
                end
              end
              # List of possible choices to be selected
              attr_reader :choices
              # The id of the selected choice
              attr_reader :id
              # The text of the selected choice
              attr_reader :text

              def self.inner_class_types
                @inner_class_types = { choices: Choice }
              end

              def self.field_remappings
                @field_remappings = {}
              end
            end

            class Signature < ::Stripe::StripeObject
              # The File ID of a collected signature image
              attr_reader :value

              def self.inner_class_types
                @inner_class_types = {}
              end

              def self.field_remappings
                @field_remappings = {}
              end
            end

            class Text < ::Stripe::StripeObject
              # The collected text value
              attr_reader :value

              def self.inner_class_types
                @inner_class_types = {}
              end

              def self.field_remappings
                @field_remappings = {}
              end
            end

            class Toggle < ::Stripe::StripeObject
              # The toggle's default value. Can be `enabled` or `disabled`.
              attr_reader :default_value
              # The toggle's description text. Maximum 50 characters.
              attr_reader :description
              # The toggle's title text. Maximum 50 characters.
              attr_reader :title
              # The toggle's collected value. Can be `enabled` or `disabled`.
              attr_reader :value

              def self.inner_class_types
                @inner_class_types = {}
              end

              def self.field_remappings
                @field_remappings = {}
              end
            end
            # Default text of input being collected.
            attr_reader :custom_text
            # Information about a email being collected using a reader
            attr_reader :email
            # Information about a number being collected using a reader
            attr_reader :numeric
            # Information about a phone number being collected using a reader
            attr_reader :phone
            # Indicate that this input is required, disabling the skip button.
            attr_reader :required
            # Information about a selection being collected using a reader
            attr_reader :selection
            # Information about a signature being collected using a reader
            attr_reader :signature
            # Indicate that this input was skipped by the user.
            attr_reader :skipped
            # Information about text being collected using a reader
            attr_reader :text
            # List of toggles being collected. Values are present if collection is complete.
            attr_reader :toggles
            # Type of input being collected.
            attr_reader :type

            def self.inner_class_types
              @inner_class_types = {
                custom_text: CustomText,
                email: Email,
                numeric: Numeric,
                phone: Phone,
                selection: Selection,
                signature: Signature,
                text: Text,
                toggles: Toggle,
              }
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # List of inputs to be collected.
          attr_reader :inputs
          # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
          attr_reader :metadata

          def self.inner_class_types
            @inner_class_types = { inputs: Input }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class CollectPaymentMethod < ::Stripe::StripeObject
          class CollectConfig < ::Stripe::StripeObject
            class Tipping < ::Stripe::StripeObject
              # Amount used to calculate tip suggestions on tipping selection screen for this transaction. Must be a positive integer in the smallest currency unit (e.g., 100 cents to represent $1.00 or 100 to represent ¥100, a zero-decimal currency).
              attr_reader :amount_eligible

              def self.inner_class_types
                @inner_class_types = {}
              end

              def self.field_remappings
                @field_remappings = {}
              end
            end
            # Enable customer-initiated cancellation when processing this payment.
            attr_reader :enable_customer_cancellation
            # Override showing a tipping selection screen on this transaction.
            attr_reader :skip_tipping
            # Represents a per-transaction tipping configuration
            attr_reader :tipping

            def self.inner_class_types
              @inner_class_types = { tipping: Tipping }
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Represents a per-transaction override of a reader configuration
          attr_reader :collect_config
          # Most recent PaymentIntent processed by the reader.
          attr_reader :payment_intent
          # PaymentMethod objects represent your customer's payment instruments.
          # You can use them with [PaymentIntents](https://stripe.com/docs/payments/payment-intents) to collect payments or save them to
          # Customer objects to store instrument details for future payments.
          #
          # Related guides: [Payment Methods](https://stripe.com/docs/payments/payment-methods) and [More Payment Scenarios](https://stripe.com/docs/payments/more-payment-scenarios).
          attr_reader :payment_method

          def self.inner_class_types
            @inner_class_types = { collect_config: CollectConfig }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class ConfirmPaymentIntent < ::Stripe::StripeObject
          class ConfirmConfig < ::Stripe::StripeObject
            # If the customer doesn't abandon authenticating the payment, they're redirected to this URL after completion.
            attr_reader :return_url

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Represents a per-transaction override of a reader configuration
          attr_reader :confirm_config
          # Most recent PaymentIntent processed by the reader.
          attr_reader :payment_intent

          def self.inner_class_types
            @inner_class_types = { confirm_config: ConfirmConfig }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class ProcessPaymentIntent < ::Stripe::StripeObject
          class ProcessConfig < ::Stripe::StripeObject
            class Tipping < ::Stripe::StripeObject
              # Amount used to calculate tip suggestions on tipping selection screen for this transaction. Must be a positive integer in the smallest currency unit (e.g., 100 cents to represent $1.00 or 100 to represent ¥100, a zero-decimal currency).
              attr_reader :amount_eligible

              def self.inner_class_types
                @inner_class_types = {}
              end

              def self.field_remappings
                @field_remappings = {}
              end
            end
            # Enable customer-initiated cancellation when processing this payment.
            attr_reader :enable_customer_cancellation
            # If the customer doesn't abandon authenticating the payment, they're redirected to this URL after completion.
            attr_reader :return_url
            # Override showing a tipping selection screen on this transaction.
            attr_reader :skip_tipping
            # Represents a per-transaction tipping configuration
            attr_reader :tipping

            def self.inner_class_types
              @inner_class_types = { tipping: Tipping }
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Most recent PaymentIntent processed by the reader.
          attr_reader :payment_intent
          # Represents a per-transaction override of a reader configuration
          attr_reader :process_config

          def self.inner_class_types
            @inner_class_types = { process_config: ProcessConfig }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class ProcessSetupIntent < ::Stripe::StripeObject
          class ProcessConfig < ::Stripe::StripeObject
            # Enable customer-initiated cancellation when processing this SetupIntent.
            attr_reader :enable_customer_cancellation

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # ID of a card PaymentMethod generated from the card_present PaymentMethod that may be attached to a Customer for future transactions. Only present if it was possible to generate a card PaymentMethod.
          attr_reader :generated_card
          # Represents a per-setup override of a reader configuration
          attr_reader :process_config
          # Most recent SetupIntent processed by the reader.
          attr_reader :setup_intent

          def self.inner_class_types
            @inner_class_types = { process_config: ProcessConfig }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class RefundPayment < ::Stripe::StripeObject
          class RefundPaymentConfig < ::Stripe::StripeObject
            # Enable customer-initiated cancellation when refunding this payment.
            attr_reader :enable_customer_cancellation

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # The amount being refunded.
          attr_reader :amount
          # Charge that is being refunded.
          attr_reader :charge
          # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
          attr_reader :metadata
          # Payment intent that is being refunded.
          attr_reader :payment_intent
          # The reason for the refund.
          attr_reader :reason
          # Unique identifier for the refund object.
          attr_reader :refund
          # Boolean indicating whether the application fee should be refunded when refunding this charge. If a full charge refund is given, the full application fee will be refunded. Otherwise, the application fee will be refunded in an amount proportional to the amount of the charge refunded. An application fee can be refunded only by the application that created the charge.
          attr_reader :refund_application_fee
          # Represents a per-transaction override of a reader configuration
          attr_reader :refund_payment_config
          # Boolean indicating whether the transfer should be reversed when refunding this charge. The transfer will be reversed proportionally to the amount being refunded (either the entire or partial amount). A transfer can be reversed only by the application that created the charge.
          attr_reader :reverse_transfer

          def self.inner_class_types
            @inner_class_types = { refund_payment_config: RefundPaymentConfig }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class SetReaderDisplay < ::Stripe::StripeObject
          class Cart < ::Stripe::StripeObject
            class LineItem < ::Stripe::StripeObject
              # The amount of the line item. A positive integer in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal).
              attr_reader :amount
              # Description of the line item.
              attr_reader :description
              # The quantity of the line item.
              attr_reader :quantity

              def self.inner_class_types
                @inner_class_types = {}
              end

              def self.field_remappings
                @field_remappings = {}
              end
            end
            # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
            attr_reader :currency
            # List of line items in the cart.
            attr_reader :line_items
            # Tax amount for the entire cart. A positive integer in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal).
            attr_reader :tax
            # Total amount for the entire cart, including tax. A positive integer in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal).
            attr_reader :total

            def self.inner_class_types
              @inner_class_types = { line_items: LineItem }
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Cart object to be displayed by the reader, including line items, amounts, and currency.
          attr_reader :cart
          # Type of information to be displayed by the reader. Only `cart` is currently supported.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { cart: Cart }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Represents a reader action to collect customer inputs
        attr_reader :collect_inputs
        # Represents a reader action to collect a payment method
        attr_reader :collect_payment_method
        # Represents a reader action to confirm a payment
        attr_reader :confirm_payment_intent
        # Failure code, only set if status is `failed`.
        attr_reader :failure_code
        # Detailed failure message, only set if status is `failed`.
        attr_reader :failure_message
        # Represents a reader action to process a payment intent
        attr_reader :process_payment_intent
        # Represents a reader action to process a setup intent
        attr_reader :process_setup_intent
        # Represents a reader action to refund a payment
        attr_reader :refund_payment
        # Represents a reader action to set the reader display
        attr_reader :set_reader_display
        # Status of the action performed by the reader.
        attr_reader :status
        # Type of action performed by the reader.
        attr_reader :type

        def self.inner_class_types
          @inner_class_types = {
            collect_inputs: CollectInputs,
            collect_payment_method: CollectPaymentMethod,
            confirm_payment_intent: ConfirmPaymentIntent,
            process_payment_intent: ProcessPaymentIntent,
            process_setup_intent: ProcessSetupIntent,
            refund_payment: RefundPayment,
            set_reader_display: SetReaderDisplay,
          }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # The most recent action performed by the reader.
      attr_reader :action
      # The current software version of the reader.
      attr_reader :device_sw_version
      # Device type of the reader.
      attr_reader :device_type
      # Unique identifier for the object.
      attr_reader :id
      # The local IP address of the reader.
      attr_reader :ip_address
      # Custom label given to the reader for easier identification.
      attr_reader :label
      # The last time this reader reported to Stripe backend.
      attr_reader :last_seen_at
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # The location identifier of the reader.
      attr_reader :location
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
      attr_reader :metadata
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # Serial number of the reader.
      attr_reader :serial_number
      # The networking status of the reader. We do not recommend using this field in flows that may block taking payments.
      attr_reader :status
      # Always true for a deleted object
      attr_reader :deleted

      # Cancels the current reader action. See [Programmatic Cancellation](https://docs.stripe.com/docs/terminal/payments/collect-card-payment?terminal-sdk-platform=server-driven#programmatic-cancellation) for more details.
      def cancel_action(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/terminal/readers/%<reader>s/cancel_action", { reader: CGI.escape(self["id"]) }),
          params: params,
          opts: opts
        )
      end

      # Cancels the current reader action. See [Programmatic Cancellation](https://docs.stripe.com/docs/terminal/payments/collect-card-payment?terminal-sdk-platform=server-driven#programmatic-cancellation) for more details.
      def self.cancel_action(reader, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/terminal/readers/%<reader>s/cancel_action", { reader: CGI.escape(reader) }),
          params: params,
          opts: opts
        )
      end

      # Initiates an [input collection flow](https://docs.stripe.com/docs/terminal/features/collect-inputs) on a Reader to display input forms and collect information from your customers.
      def collect_inputs(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/terminal/readers/%<reader>s/collect_inputs", { reader: CGI.escape(self["id"]) }),
          params: params,
          opts: opts
        )
      end

      # Initiates an [input collection flow](https://docs.stripe.com/docs/terminal/features/collect-inputs) on a Reader to display input forms and collect information from your customers.
      def self.collect_inputs(reader, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/terminal/readers/%<reader>s/collect_inputs", { reader: CGI.escape(reader) }),
          params: params,
          opts: opts
        )
      end

      # Initiates a payment flow on a Reader and updates the PaymentIntent with card details before manual confirmation. See [Collecting a Payment method](https://docs.stripe.com/docs/terminal/payments/collect-card-payment?terminal-sdk-platform=server-driven&process=inspect#collect-a-paymentmethod) for more details.
      def collect_payment_method(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/terminal/readers/%<reader>s/collect_payment_method", { reader: CGI.escape(self["id"]) }),
          params: params,
          opts: opts
        )
      end

      # Initiates a payment flow on a Reader and updates the PaymentIntent with card details before manual confirmation. See [Collecting a Payment method](https://docs.stripe.com/docs/terminal/payments/collect-card-payment?terminal-sdk-platform=server-driven&process=inspect#collect-a-paymentmethod) for more details.
      def self.collect_payment_method(reader, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/terminal/readers/%<reader>s/collect_payment_method", { reader: CGI.escape(reader) }),
          params: params,
          opts: opts
        )
      end

      # Finalizes a payment on a Reader. See [Confirming a Payment](https://docs.stripe.com/docs/terminal/payments/collect-card-payment?terminal-sdk-platform=server-driven&process=inspect#confirm-the-paymentintent) for more details.
      def confirm_payment_intent(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/terminal/readers/%<reader>s/confirm_payment_intent", { reader: CGI.escape(self["id"]) }),
          params: params,
          opts: opts
        )
      end

      # Finalizes a payment on a Reader. See [Confirming a Payment](https://docs.stripe.com/docs/terminal/payments/collect-card-payment?terminal-sdk-platform=server-driven&process=inspect#confirm-the-paymentintent) for more details.
      def self.confirm_payment_intent(reader, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/terminal/readers/%<reader>s/confirm_payment_intent", { reader: CGI.escape(reader) }),
          params: params,
          opts: opts
        )
      end

      # Creates a new Reader object.
      def self.create(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: "/v1/terminal/readers",
          params: params,
          opts: opts
        )
      end

      # Deletes a Reader object.
      def self.delete(reader, params = {}, opts = {})
        request_stripe_object(
          method: :delete,
          path: format("/v1/terminal/readers/%<reader>s", { reader: CGI.escape(reader) }),
          params: params,
          opts: opts
        )
      end

      # Deletes a Reader object.
      def delete(params = {}, opts = {})
        request_stripe_object(
          method: :delete,
          path: format("/v1/terminal/readers/%<reader>s", { reader: CGI.escape(self["id"]) }),
          params: params,
          opts: opts
        )
      end

      # Returns a list of Reader objects.
      def self.list(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: "/v1/terminal/readers",
          params: params,
          opts: opts
        )
      end

      # Initiates a payment flow on a Reader. See [process the payment](https://docs.stripe.com/docs/terminal/payments/collect-card-payment?terminal-sdk-platform=server-driven&process=immediately#process-payment) for more details.
      def process_payment_intent(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/terminal/readers/%<reader>s/process_payment_intent", { reader: CGI.escape(self["id"]) }),
          params: params,
          opts: opts
        )
      end

      # Initiates a payment flow on a Reader. See [process the payment](https://docs.stripe.com/docs/terminal/payments/collect-card-payment?terminal-sdk-platform=server-driven&process=immediately#process-payment) for more details.
      def self.process_payment_intent(reader, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/terminal/readers/%<reader>s/process_payment_intent", { reader: CGI.escape(reader) }),
          params: params,
          opts: opts
        )
      end

      # Initiates a SetupIntent flow on a Reader. See [Save directly without charging](https://docs.stripe.com/docs/terminal/features/saving-payment-details/save-directly) for more details.
      def process_setup_intent(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/terminal/readers/%<reader>s/process_setup_intent", { reader: CGI.escape(self["id"]) }),
          params: params,
          opts: opts
        )
      end

      # Initiates a SetupIntent flow on a Reader. See [Save directly without charging](https://docs.stripe.com/docs/terminal/features/saving-payment-details/save-directly) for more details.
      def self.process_setup_intent(reader, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/terminal/readers/%<reader>s/process_setup_intent", { reader: CGI.escape(reader) }),
          params: params,
          opts: opts
        )
      end

      # Initiates an in-person refund on a Reader. See [Refund an Interac Payment](https://docs.stripe.com/docs/terminal/payments/regional?integration-country=CA#refund-an-interac-payment) for more details.
      def refund_payment(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/terminal/readers/%<reader>s/refund_payment", { reader: CGI.escape(self["id"]) }),
          params: params,
          opts: opts
        )
      end

      # Initiates an in-person refund on a Reader. See [Refund an Interac Payment](https://docs.stripe.com/docs/terminal/payments/regional?integration-country=CA#refund-an-interac-payment) for more details.
      def self.refund_payment(reader, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/terminal/readers/%<reader>s/refund_payment", { reader: CGI.escape(reader) }),
          params: params,
          opts: opts
        )
      end

      # Sets the reader display to show [cart details](https://docs.stripe.com/docs/terminal/features/display).
      def set_reader_display(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/terminal/readers/%<reader>s/set_reader_display", { reader: CGI.escape(self["id"]) }),
          params: params,
          opts: opts
        )
      end

      # Sets the reader display to show [cart details](https://docs.stripe.com/docs/terminal/features/display).
      def self.set_reader_display(reader, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/terminal/readers/%<reader>s/set_reader_display", { reader: CGI.escape(reader) }),
          params: params,
          opts: opts
        )
      end

      # Updates a Reader object by setting the values of the parameters passed. Any parameters not provided will be left unchanged.
      def self.update(reader, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/terminal/readers/%<reader>s", { reader: CGI.escape(reader) }),
          params: params,
          opts: opts
        )
      end

      def test_helpers
        TestHelpers.new(self)
      end

      class TestHelpers < APIResourceTestHelpers
        RESOURCE_CLASS = Reader
        def self.resource_class
          "Reader"
        end

        # Presents a payment method on a simulated reader. Can be used to simulate accepting a payment, saving a card or refunding a transaction.
        def self.present_payment_method(reader, params = {}, opts = {})
          request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/terminal/readers/%<reader>s/present_payment_method", { reader: CGI.escape(reader) }),
            params: params,
            opts: opts
          )
        end

        # Presents a payment method on a simulated reader. Can be used to simulate accepting a payment, saving a card or refunding a transaction.
        def present_payment_method(params = {}, opts = {})
          @resource.request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/terminal/readers/%<reader>s/present_payment_method", { reader: CGI.escape(@resource["id"]) }),
            params: params,
            opts: opts
          )
        end

        # Use this endpoint to trigger a successful input collection on a simulated reader.
        def self.succeed_input_collection(reader, params = {}, opts = {})
          request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/terminal/readers/%<reader>s/succeed_input_collection", { reader: CGI.escape(reader) }),
            params: params,
            opts: opts
          )
        end

        # Use this endpoint to trigger a successful input collection on a simulated reader.
        def succeed_input_collection(params = {}, opts = {})
          @resource.request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/terminal/readers/%<reader>s/succeed_input_collection", { reader: CGI.escape(@resource["id"]) }),
            params: params,
            opts: opts
          )
        end

        # Use this endpoint to complete an input collection with a timeout error on a simulated reader.
        def self.timeout_input_collection(reader, params = {}, opts = {})
          request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/terminal/readers/%<reader>s/timeout_input_collection", { reader: CGI.escape(reader) }),
            params: params,
            opts: opts
          )
        end

        # Use this endpoint to complete an input collection with a timeout error on a simulated reader.
        def timeout_input_collection(params = {}, opts = {})
          @resource.request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/terminal/readers/%<reader>s/timeout_input_collection", { reader: CGI.escape(@resource["id"]) }),
            params: params,
            opts: opts
          )
        end
      end

      def self.inner_class_types
        @inner_class_types = { action: Action }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
