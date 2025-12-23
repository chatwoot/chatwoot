# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Terminal
    # A Configurations object represents how features should be configured for terminal readers.
    # For information about how to use it, see the [Terminal configurations documentation](https://docs.stripe.com/terminal/fleet/configurations-overview).
    class Configuration < APIResource
      extend Stripe::APIOperations::Create
      include Stripe::APIOperations::Delete
      extend Stripe::APIOperations::List
      include Stripe::APIOperations::Save

      OBJECT_NAME = "terminal.configuration"
      def self.object_name
        "terminal.configuration"
      end

      class BbposWisepad3 < ::Stripe::StripeObject
        # A File ID representing an image to display on the reader
        attr_reader :splashscreen

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class BbposWiseposE < ::Stripe::StripeObject
        # A File ID representing an image to display on the reader
        attr_reader :splashscreen

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Offline < ::Stripe::StripeObject
        # Determines whether to allow transactions to be collected while reader is offline. Defaults to false.
        attr_reader :enabled

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class RebootWindow < ::Stripe::StripeObject
        # Integer between 0 to 23 that represents the end hour of the reboot time window. The value must be different than the start_hour.
        attr_reader :end_hour
        # Integer between 0 to 23 that represents the start hour of the reboot time window.
        attr_reader :start_hour

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class StripeS700 < ::Stripe::StripeObject
        # A File ID representing an image to display on the reader
        attr_reader :splashscreen

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Tipping < ::Stripe::StripeObject
        class Aed < ::Stripe::StripeObject
          # Fixed amounts displayed when collecting a tip
          attr_reader :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_reader :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_reader :smart_tip_threshold

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Aud < ::Stripe::StripeObject
          # Fixed amounts displayed when collecting a tip
          attr_reader :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_reader :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_reader :smart_tip_threshold

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Bgn < ::Stripe::StripeObject
          # Fixed amounts displayed when collecting a tip
          attr_reader :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_reader :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_reader :smart_tip_threshold

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Cad < ::Stripe::StripeObject
          # Fixed amounts displayed when collecting a tip
          attr_reader :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_reader :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_reader :smart_tip_threshold

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Chf < ::Stripe::StripeObject
          # Fixed amounts displayed when collecting a tip
          attr_reader :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_reader :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_reader :smart_tip_threshold

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Czk < ::Stripe::StripeObject
          # Fixed amounts displayed when collecting a tip
          attr_reader :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_reader :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_reader :smart_tip_threshold

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Dkk < ::Stripe::StripeObject
          # Fixed amounts displayed when collecting a tip
          attr_reader :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_reader :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_reader :smart_tip_threshold

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Eur < ::Stripe::StripeObject
          # Fixed amounts displayed when collecting a tip
          attr_reader :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_reader :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_reader :smart_tip_threshold

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Gbp < ::Stripe::StripeObject
          # Fixed amounts displayed when collecting a tip
          attr_reader :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_reader :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_reader :smart_tip_threshold

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Gip < ::Stripe::StripeObject
          # Fixed amounts displayed when collecting a tip
          attr_reader :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_reader :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_reader :smart_tip_threshold

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Hkd < ::Stripe::StripeObject
          # Fixed amounts displayed when collecting a tip
          attr_reader :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_reader :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_reader :smart_tip_threshold

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Huf < ::Stripe::StripeObject
          # Fixed amounts displayed when collecting a tip
          attr_reader :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_reader :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_reader :smart_tip_threshold

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Jpy < ::Stripe::StripeObject
          # Fixed amounts displayed when collecting a tip
          attr_reader :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_reader :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_reader :smart_tip_threshold

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Mxn < ::Stripe::StripeObject
          # Fixed amounts displayed when collecting a tip
          attr_reader :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_reader :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_reader :smart_tip_threshold

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Myr < ::Stripe::StripeObject
          # Fixed amounts displayed when collecting a tip
          attr_reader :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_reader :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_reader :smart_tip_threshold

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Nok < ::Stripe::StripeObject
          # Fixed amounts displayed when collecting a tip
          attr_reader :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_reader :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_reader :smart_tip_threshold

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Nzd < ::Stripe::StripeObject
          # Fixed amounts displayed when collecting a tip
          attr_reader :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_reader :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_reader :smart_tip_threshold

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Pln < ::Stripe::StripeObject
          # Fixed amounts displayed when collecting a tip
          attr_reader :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_reader :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_reader :smart_tip_threshold

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Ron < ::Stripe::StripeObject
          # Fixed amounts displayed when collecting a tip
          attr_reader :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_reader :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_reader :smart_tip_threshold

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Sek < ::Stripe::StripeObject
          # Fixed amounts displayed when collecting a tip
          attr_reader :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_reader :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_reader :smart_tip_threshold

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Sgd < ::Stripe::StripeObject
          # Fixed amounts displayed when collecting a tip
          attr_reader :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_reader :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_reader :smart_tip_threshold

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Usd < ::Stripe::StripeObject
          # Fixed amounts displayed when collecting a tip
          attr_reader :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_reader :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_reader :smart_tip_threshold

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Attribute for field aed
        attr_reader :aed
        # Attribute for field aud
        attr_reader :aud
        # Attribute for field bgn
        attr_reader :bgn
        # Attribute for field cad
        attr_reader :cad
        # Attribute for field chf
        attr_reader :chf
        # Attribute for field czk
        attr_reader :czk
        # Attribute for field dkk
        attr_reader :dkk
        # Attribute for field eur
        attr_reader :eur
        # Attribute for field gbp
        attr_reader :gbp
        # Attribute for field gip
        attr_reader :gip
        # Attribute for field hkd
        attr_reader :hkd
        # Attribute for field huf
        attr_reader :huf
        # Attribute for field jpy
        attr_reader :jpy
        # Attribute for field mxn
        attr_reader :mxn
        # Attribute for field myr
        attr_reader :myr
        # Attribute for field nok
        attr_reader :nok
        # Attribute for field nzd
        attr_reader :nzd
        # Attribute for field pln
        attr_reader :pln
        # Attribute for field ron
        attr_reader :ron
        # Attribute for field sek
        attr_reader :sek
        # Attribute for field sgd
        attr_reader :sgd
        # Attribute for field usd
        attr_reader :usd

        def self.inner_class_types
          @inner_class_types = {
            aed: Aed,
            aud: Aud,
            bgn: Bgn,
            cad: Cad,
            chf: Chf,
            czk: Czk,
            dkk: Dkk,
            eur: Eur,
            gbp: Gbp,
            gip: Gip,
            hkd: Hkd,
            huf: Huf,
            jpy: Jpy,
            mxn: Mxn,
            myr: Myr,
            nok: Nok,
            nzd: Nzd,
            pln: Pln,
            ron: Ron,
            sek: Sek,
            sgd: Sgd,
            usd: Usd,
          }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class VerifoneP400 < ::Stripe::StripeObject
        # A File ID representing an image to display on the reader
        attr_reader :splashscreen

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Wifi < ::Stripe::StripeObject
        class EnterpriseEapPeap < ::Stripe::StripeObject
          # A File ID representing a PEM file containing the server certificate
          attr_reader :ca_certificate_file
          # Password for connecting to the WiFi network
          attr_reader :password
          # Name of the WiFi network
          attr_reader :ssid
          # Username for connecting to the WiFi network
          attr_reader :username

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class EnterpriseEapTls < ::Stripe::StripeObject
          # A File ID representing a PEM file containing the server certificate
          attr_reader :ca_certificate_file
          # A File ID representing a PEM file containing the client certificate
          attr_reader :client_certificate_file
          # A File ID representing a PEM file containing the client RSA private key
          attr_reader :private_key_file
          # Password for the private key file
          attr_reader :private_key_file_password
          # Name of the WiFi network
          attr_reader :ssid

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class PersonalPsk < ::Stripe::StripeObject
          # Password for connecting to the WiFi network
          attr_reader :password
          # Name of the WiFi network
          attr_reader :ssid

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Attribute for field enterprise_eap_peap
        attr_reader :enterprise_eap_peap
        # Attribute for field enterprise_eap_tls
        attr_reader :enterprise_eap_tls
        # Attribute for field personal_psk
        attr_reader :personal_psk
        # Security type of the WiFi network. The hash with the corresponding name contains the credentials for this security type.
        attr_reader :type

        def self.inner_class_types
          @inner_class_types = {
            enterprise_eap_peap: EnterpriseEapPeap,
            enterprise_eap_tls: EnterpriseEapTls,
            personal_psk: PersonalPsk,
          }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Attribute for field bbpos_wisepad3
      attr_reader :bbpos_wisepad3
      # Attribute for field bbpos_wisepos_e
      attr_reader :bbpos_wisepos_e
      # Unique identifier for the object.
      attr_reader :id
      # Whether this Configuration is the default for your account
      attr_reader :is_account_default
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # String indicating the name of the Configuration object, set by the user
      attr_reader :name
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # Attribute for field offline
      attr_reader :offline
      # Attribute for field reboot_window
      attr_reader :reboot_window
      # Attribute for field stripe_s700
      attr_reader :stripe_s700
      # Attribute for field tipping
      attr_reader :tipping
      # Attribute for field verifone_p400
      attr_reader :verifone_p400
      # Attribute for field wifi
      attr_reader :wifi
      # Always true for a deleted object
      attr_reader :deleted

      # Creates a new Configuration object.
      def self.create(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: "/v1/terminal/configurations",
          params: params,
          opts: opts
        )
      end

      # Deletes a Configuration object.
      def self.delete(configuration, params = {}, opts = {})
        request_stripe_object(
          method: :delete,
          path: format("/v1/terminal/configurations/%<configuration>s", { configuration: CGI.escape(configuration) }),
          params: params,
          opts: opts
        )
      end

      # Deletes a Configuration object.
      def delete(params = {}, opts = {})
        request_stripe_object(
          method: :delete,
          path: format("/v1/terminal/configurations/%<configuration>s", { configuration: CGI.escape(self["id"]) }),
          params: params,
          opts: opts
        )
      end

      # Returns a list of Configuration objects.
      def self.list(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: "/v1/terminal/configurations",
          params: params,
          opts: opts
        )
      end

      # Updates a new Configuration object.
      def self.update(configuration, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/terminal/configurations/%<configuration>s", { configuration: CGI.escape(configuration) }),
          params: params,
          opts: opts
        )
      end

      def self.inner_class_types
        @inner_class_types = {
          bbpos_wisepad3: BbposWisepad3,
          bbpos_wisepos_e: BbposWiseposE,
          offline: Offline,
          reboot_window: RebootWindow,
          stripe_s700: StripeS700,
          tipping: Tipping,
          verifone_p400: VerifoneP400,
          wifi: Wifi,
        }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
