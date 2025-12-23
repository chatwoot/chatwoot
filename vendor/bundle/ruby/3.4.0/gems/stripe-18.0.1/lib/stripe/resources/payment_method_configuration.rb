# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # PaymentMethodConfigurations control which payment methods are displayed to your customers when you don't explicitly specify payment method types. You can have multiple configurations with different sets of payment methods for different scenarios.
  #
  # There are two types of PaymentMethodConfigurations. Which is used depends on the [charge type](https://stripe.com/docs/connect/charges):
  #
  # **Direct** configurations apply to payments created on your account, including Connect destination charges, Connect separate charges and transfers, and payments not involving Connect.
  #
  # **Child** configurations apply to payments created on your connected accounts using direct charges, and charges with the on_behalf_of parameter.
  #
  # Child configurations have a `parent` that sets default values and controls which settings connected accounts may override. You can specify a parent ID at payment time, and Stripe will automatically resolve the connected account's associated child configuration. Parent configurations are [managed in the dashboard](https://dashboard.stripe.com/settings/payment_methods/connected_accounts) and are not available in this API.
  #
  # Related guides:
  # - [Payment Method Configurations API](https://stripe.com/docs/connect/payment-method-configurations)
  # - [Multiple configurations on dynamic payment methods](https://stripe.com/docs/payments/multiple-payment-method-configs)
  # - [Multiple configurations for your Connect accounts](https://stripe.com/docs/connect/multiple-payment-method-configurations)
  class PaymentMethodConfiguration < APIResource
    extend Stripe::APIOperations::Create
    extend Stripe::APIOperations::List
    include Stripe::APIOperations::Save

    OBJECT_NAME = "payment_method_configuration"
    def self.object_name
      "payment_method_configuration"
    end

    class AcssDebit < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Affirm < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class AfterpayClearpay < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Alipay < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Alma < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class AmazonPay < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class ApplePay < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class AuBecsDebit < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class BacsDebit < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Bancontact < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Billie < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Blik < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Boleto < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Card < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class CartesBancaires < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Cashapp < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Crypto < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class CustomerBalance < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Eps < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Fpx < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Giropay < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class GooglePay < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Grabpay < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Ideal < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Jcb < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class KakaoPay < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Klarna < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Konbini < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class KrCard < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Link < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class MbWay < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Mobilepay < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Multibanco < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class NaverPay < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class NzBankAccount < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Oxxo < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class P24 < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class PayByBank < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Payco < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Paynow < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Paypal < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Pix < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Promptpay < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class RevolutPay < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class SamsungPay < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Satispay < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class SepaDebit < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Sofort < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Swish < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Twint < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class UsBankAccount < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class WechatPay < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Zip < ::Stripe::StripeObject
      class DisplayPreference < ::Stripe::StripeObject
        # For child configs, whether or not the account's preference will be observed. If `false`, the parent configuration's default is used.
        attr_reader :overridable
        # The account's display preference.
        attr_reader :preference
        # The effective display preference value.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Whether this payment method may be offered at checkout. True if `display_preference` is `on` and the payment method's capability is active.
      attr_reader :available
      # Attribute for field display_preference
      attr_reader :display_preference

      def self.inner_class_types
        @inner_class_types = { display_preference: DisplayPreference }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
    # Attribute for field acss_debit
    attr_reader :acss_debit
    # Whether the configuration can be used for new payments.
    attr_reader :active
    # Attribute for field affirm
    attr_reader :affirm
    # Attribute for field afterpay_clearpay
    attr_reader :afterpay_clearpay
    # Attribute for field alipay
    attr_reader :alipay
    # Attribute for field alma
    attr_reader :alma
    # Attribute for field amazon_pay
    attr_reader :amazon_pay
    # Attribute for field apple_pay
    attr_reader :apple_pay
    # For child configs, the Connect application associated with the configuration.
    attr_reader :application
    # Attribute for field au_becs_debit
    attr_reader :au_becs_debit
    # Attribute for field bacs_debit
    attr_reader :bacs_debit
    # Attribute for field bancontact
    attr_reader :bancontact
    # Attribute for field billie
    attr_reader :billie
    # Attribute for field blik
    attr_reader :blik
    # Attribute for field boleto
    attr_reader :boleto
    # Attribute for field card
    attr_reader :card
    # Attribute for field cartes_bancaires
    attr_reader :cartes_bancaires
    # Attribute for field cashapp
    attr_reader :cashapp
    # Attribute for field crypto
    attr_reader :crypto
    # Attribute for field customer_balance
    attr_reader :customer_balance
    # Attribute for field eps
    attr_reader :eps
    # Attribute for field fpx
    attr_reader :fpx
    # Attribute for field giropay
    attr_reader :giropay
    # Attribute for field google_pay
    attr_reader :google_pay
    # Attribute for field grabpay
    attr_reader :grabpay
    # Unique identifier for the object.
    attr_reader :id
    # Attribute for field ideal
    attr_reader :ideal
    # The default configuration is used whenever a payment method configuration is not specified.
    attr_reader :is_default
    # Attribute for field jcb
    attr_reader :jcb
    # Attribute for field kakao_pay
    attr_reader :kakao_pay
    # Attribute for field klarna
    attr_reader :klarna
    # Attribute for field konbini
    attr_reader :konbini
    # Attribute for field kr_card
    attr_reader :kr_card
    # Attribute for field link
    attr_reader :link
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # Attribute for field mb_way
    attr_reader :mb_way
    # Attribute for field mobilepay
    attr_reader :mobilepay
    # Attribute for field multibanco
    attr_reader :multibanco
    # The configuration's name.
    attr_reader :name
    # Attribute for field naver_pay
    attr_reader :naver_pay
    # Attribute for field nz_bank_account
    attr_reader :nz_bank_account
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # Attribute for field oxxo
    attr_reader :oxxo
    # Attribute for field p24
    attr_reader :p24
    # For child configs, the configuration's parent configuration.
    attr_reader :parent
    # Attribute for field pay_by_bank
    attr_reader :pay_by_bank
    # Attribute for field payco
    attr_reader :payco
    # Attribute for field paynow
    attr_reader :paynow
    # Attribute for field paypal
    attr_reader :paypal
    # Attribute for field pix
    attr_reader :pix
    # Attribute for field promptpay
    attr_reader :promptpay
    # Attribute for field revolut_pay
    attr_reader :revolut_pay
    # Attribute for field samsung_pay
    attr_reader :samsung_pay
    # Attribute for field satispay
    attr_reader :satispay
    # Attribute for field sepa_debit
    attr_reader :sepa_debit
    # Attribute for field sofort
    attr_reader :sofort
    # Attribute for field swish
    attr_reader :swish
    # Attribute for field twint
    attr_reader :twint
    # Attribute for field us_bank_account
    attr_reader :us_bank_account
    # Attribute for field wechat_pay
    attr_reader :wechat_pay
    # Attribute for field zip
    attr_reader :zip

    # Creates a payment method configuration
    def self.create(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: "/v1/payment_method_configurations",
        params: params,
        opts: opts
      )
    end

    # List payment method configurations
    def self.list(params = {}, opts = {})
      request_stripe_object(
        method: :get,
        path: "/v1/payment_method_configurations",
        params: params,
        opts: opts
      )
    end

    # Update payment method configuration
    def self.update(configuration, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/payment_method_configurations/%<configuration>s", { configuration: CGI.escape(configuration) }),
        params: params,
        opts: opts
      )
    end

    def self.inner_class_types
      @inner_class_types = {
        acss_debit: AcssDebit,
        affirm: Affirm,
        afterpay_clearpay: AfterpayClearpay,
        alipay: Alipay,
        alma: Alma,
        amazon_pay: AmazonPay,
        apple_pay: ApplePay,
        au_becs_debit: AuBecsDebit,
        bacs_debit: BacsDebit,
        bancontact: Bancontact,
        billie: Billie,
        blik: Blik,
        boleto: Boleto,
        card: Card,
        cartes_bancaires: CartesBancaires,
        cashapp: Cashapp,
        crypto: Crypto,
        customer_balance: CustomerBalance,
        eps: Eps,
        fpx: Fpx,
        giropay: Giropay,
        google_pay: GooglePay,
        grabpay: Grabpay,
        ideal: Ideal,
        jcb: Jcb,
        kakao_pay: KakaoPay,
        klarna: Klarna,
        konbini: Konbini,
        kr_card: KrCard,
        link: Link,
        mb_way: MbWay,
        mobilepay: Mobilepay,
        multibanco: Multibanco,
        naver_pay: NaverPay,
        nz_bank_account: NzBankAccount,
        oxxo: Oxxo,
        p24: P24,
        pay_by_bank: PayByBank,
        payco: Payco,
        paynow: Paynow,
        paypal: Paypal,
        pix: Pix,
        promptpay: Promptpay,
        revolut_pay: RevolutPay,
        samsung_pay: SamsungPay,
        satispay: Satispay,
        sepa_debit: SepaDebit,
        sofort: Sofort,
        swish: Swish,
        twint: Twint,
        us_bank_account: UsBankAccount,
        wechat_pay: WechatPay,
        zip: Zip,
      }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
