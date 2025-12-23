# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Terminal
    class ConfigurationUpdateParams < ::Stripe::RequestParams
      class BbposWisepad3 < ::Stripe::RequestParams
        # A File ID representing an image you want to display on the reader.
        attr_accessor :splashscreen

        def initialize(splashscreen: nil)
          @splashscreen = splashscreen
        end
      end

      class BbposWiseposE < ::Stripe::RequestParams
        # A File ID representing an image to display on the reader
        attr_accessor :splashscreen

        def initialize(splashscreen: nil)
          @splashscreen = splashscreen
        end
      end

      class Offline < ::Stripe::RequestParams
        # Determines whether to allow transactions to be collected while reader is offline. Defaults to false.
        attr_accessor :enabled

        def initialize(enabled: nil)
          @enabled = enabled
        end
      end

      class RebootWindow < ::Stripe::RequestParams
        # Integer between 0 to 23 that represents the end hour of the reboot time window. The value must be different than the start_hour.
        attr_accessor :end_hour
        # Integer between 0 to 23 that represents the start hour of the reboot time window.
        attr_accessor :start_hour

        def initialize(end_hour: nil, start_hour: nil)
          @end_hour = end_hour
          @start_hour = start_hour
        end
      end

      class StripeS700 < ::Stripe::RequestParams
        # A File ID representing an image you want to display on the reader.
        attr_accessor :splashscreen

        def initialize(splashscreen: nil)
          @splashscreen = splashscreen
        end
      end

      class Tipping < ::Stripe::RequestParams
        class Aed < ::Stripe::RequestParams
          # Fixed amounts displayed when collecting a tip
          attr_accessor :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_accessor :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_accessor :smart_tip_threshold

          def initialize(fixed_amounts: nil, percentages: nil, smart_tip_threshold: nil)
            @fixed_amounts = fixed_amounts
            @percentages = percentages
            @smart_tip_threshold = smart_tip_threshold
          end
        end

        class Aud < ::Stripe::RequestParams
          # Fixed amounts displayed when collecting a tip
          attr_accessor :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_accessor :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_accessor :smart_tip_threshold

          def initialize(fixed_amounts: nil, percentages: nil, smart_tip_threshold: nil)
            @fixed_amounts = fixed_amounts
            @percentages = percentages
            @smart_tip_threshold = smart_tip_threshold
          end
        end

        class Bgn < ::Stripe::RequestParams
          # Fixed amounts displayed when collecting a tip
          attr_accessor :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_accessor :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_accessor :smart_tip_threshold

          def initialize(fixed_amounts: nil, percentages: nil, smart_tip_threshold: nil)
            @fixed_amounts = fixed_amounts
            @percentages = percentages
            @smart_tip_threshold = smart_tip_threshold
          end
        end

        class Cad < ::Stripe::RequestParams
          # Fixed amounts displayed when collecting a tip
          attr_accessor :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_accessor :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_accessor :smart_tip_threshold

          def initialize(fixed_amounts: nil, percentages: nil, smart_tip_threshold: nil)
            @fixed_amounts = fixed_amounts
            @percentages = percentages
            @smart_tip_threshold = smart_tip_threshold
          end
        end

        class Chf < ::Stripe::RequestParams
          # Fixed amounts displayed when collecting a tip
          attr_accessor :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_accessor :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_accessor :smart_tip_threshold

          def initialize(fixed_amounts: nil, percentages: nil, smart_tip_threshold: nil)
            @fixed_amounts = fixed_amounts
            @percentages = percentages
            @smart_tip_threshold = smart_tip_threshold
          end
        end

        class Czk < ::Stripe::RequestParams
          # Fixed amounts displayed when collecting a tip
          attr_accessor :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_accessor :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_accessor :smart_tip_threshold

          def initialize(fixed_amounts: nil, percentages: nil, smart_tip_threshold: nil)
            @fixed_amounts = fixed_amounts
            @percentages = percentages
            @smart_tip_threshold = smart_tip_threshold
          end
        end

        class Dkk < ::Stripe::RequestParams
          # Fixed amounts displayed when collecting a tip
          attr_accessor :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_accessor :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_accessor :smart_tip_threshold

          def initialize(fixed_amounts: nil, percentages: nil, smart_tip_threshold: nil)
            @fixed_amounts = fixed_amounts
            @percentages = percentages
            @smart_tip_threshold = smart_tip_threshold
          end
        end

        class Eur < ::Stripe::RequestParams
          # Fixed amounts displayed when collecting a tip
          attr_accessor :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_accessor :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_accessor :smart_tip_threshold

          def initialize(fixed_amounts: nil, percentages: nil, smart_tip_threshold: nil)
            @fixed_amounts = fixed_amounts
            @percentages = percentages
            @smart_tip_threshold = smart_tip_threshold
          end
        end

        class Gbp < ::Stripe::RequestParams
          # Fixed amounts displayed when collecting a tip
          attr_accessor :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_accessor :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_accessor :smart_tip_threshold

          def initialize(fixed_amounts: nil, percentages: nil, smart_tip_threshold: nil)
            @fixed_amounts = fixed_amounts
            @percentages = percentages
            @smart_tip_threshold = smart_tip_threshold
          end
        end

        class Gip < ::Stripe::RequestParams
          # Fixed amounts displayed when collecting a tip
          attr_accessor :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_accessor :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_accessor :smart_tip_threshold

          def initialize(fixed_amounts: nil, percentages: nil, smart_tip_threshold: nil)
            @fixed_amounts = fixed_amounts
            @percentages = percentages
            @smart_tip_threshold = smart_tip_threshold
          end
        end

        class Hkd < ::Stripe::RequestParams
          # Fixed amounts displayed when collecting a tip
          attr_accessor :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_accessor :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_accessor :smart_tip_threshold

          def initialize(fixed_amounts: nil, percentages: nil, smart_tip_threshold: nil)
            @fixed_amounts = fixed_amounts
            @percentages = percentages
            @smart_tip_threshold = smart_tip_threshold
          end
        end

        class Huf < ::Stripe::RequestParams
          # Fixed amounts displayed when collecting a tip
          attr_accessor :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_accessor :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_accessor :smart_tip_threshold

          def initialize(fixed_amounts: nil, percentages: nil, smart_tip_threshold: nil)
            @fixed_amounts = fixed_amounts
            @percentages = percentages
            @smart_tip_threshold = smart_tip_threshold
          end
        end

        class Jpy < ::Stripe::RequestParams
          # Fixed amounts displayed when collecting a tip
          attr_accessor :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_accessor :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_accessor :smart_tip_threshold

          def initialize(fixed_amounts: nil, percentages: nil, smart_tip_threshold: nil)
            @fixed_amounts = fixed_amounts
            @percentages = percentages
            @smart_tip_threshold = smart_tip_threshold
          end
        end

        class Mxn < ::Stripe::RequestParams
          # Fixed amounts displayed when collecting a tip
          attr_accessor :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_accessor :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_accessor :smart_tip_threshold

          def initialize(fixed_amounts: nil, percentages: nil, smart_tip_threshold: nil)
            @fixed_amounts = fixed_amounts
            @percentages = percentages
            @smart_tip_threshold = smart_tip_threshold
          end
        end

        class Myr < ::Stripe::RequestParams
          # Fixed amounts displayed when collecting a tip
          attr_accessor :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_accessor :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_accessor :smart_tip_threshold

          def initialize(fixed_amounts: nil, percentages: nil, smart_tip_threshold: nil)
            @fixed_amounts = fixed_amounts
            @percentages = percentages
            @smart_tip_threshold = smart_tip_threshold
          end
        end

        class Nok < ::Stripe::RequestParams
          # Fixed amounts displayed when collecting a tip
          attr_accessor :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_accessor :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_accessor :smart_tip_threshold

          def initialize(fixed_amounts: nil, percentages: nil, smart_tip_threshold: nil)
            @fixed_amounts = fixed_amounts
            @percentages = percentages
            @smart_tip_threshold = smart_tip_threshold
          end
        end

        class Nzd < ::Stripe::RequestParams
          # Fixed amounts displayed when collecting a tip
          attr_accessor :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_accessor :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_accessor :smart_tip_threshold

          def initialize(fixed_amounts: nil, percentages: nil, smart_tip_threshold: nil)
            @fixed_amounts = fixed_amounts
            @percentages = percentages
            @smart_tip_threshold = smart_tip_threshold
          end
        end

        class Pln < ::Stripe::RequestParams
          # Fixed amounts displayed when collecting a tip
          attr_accessor :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_accessor :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_accessor :smart_tip_threshold

          def initialize(fixed_amounts: nil, percentages: nil, smart_tip_threshold: nil)
            @fixed_amounts = fixed_amounts
            @percentages = percentages
            @smart_tip_threshold = smart_tip_threshold
          end
        end

        class Ron < ::Stripe::RequestParams
          # Fixed amounts displayed when collecting a tip
          attr_accessor :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_accessor :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_accessor :smart_tip_threshold

          def initialize(fixed_amounts: nil, percentages: nil, smart_tip_threshold: nil)
            @fixed_amounts = fixed_amounts
            @percentages = percentages
            @smart_tip_threshold = smart_tip_threshold
          end
        end

        class Sek < ::Stripe::RequestParams
          # Fixed amounts displayed when collecting a tip
          attr_accessor :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_accessor :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_accessor :smart_tip_threshold

          def initialize(fixed_amounts: nil, percentages: nil, smart_tip_threshold: nil)
            @fixed_amounts = fixed_amounts
            @percentages = percentages
            @smart_tip_threshold = smart_tip_threshold
          end
        end

        class Sgd < ::Stripe::RequestParams
          # Fixed amounts displayed when collecting a tip
          attr_accessor :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_accessor :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_accessor :smart_tip_threshold

          def initialize(fixed_amounts: nil, percentages: nil, smart_tip_threshold: nil)
            @fixed_amounts = fixed_amounts
            @percentages = percentages
            @smart_tip_threshold = smart_tip_threshold
          end
        end

        class Usd < ::Stripe::RequestParams
          # Fixed amounts displayed when collecting a tip
          attr_accessor :fixed_amounts
          # Percentages displayed when collecting a tip
          attr_accessor :percentages
          # Below this amount, fixed amounts will be displayed; above it, percentages will be displayed
          attr_accessor :smart_tip_threshold

          def initialize(fixed_amounts: nil, percentages: nil, smart_tip_threshold: nil)
            @fixed_amounts = fixed_amounts
            @percentages = percentages
            @smart_tip_threshold = smart_tip_threshold
          end
        end
        # Tipping configuration for AED
        attr_accessor :aed
        # Tipping configuration for AUD
        attr_accessor :aud
        # Tipping configuration for BGN
        attr_accessor :bgn
        # Tipping configuration for CAD
        attr_accessor :cad
        # Tipping configuration for CHF
        attr_accessor :chf
        # Tipping configuration for CZK
        attr_accessor :czk
        # Tipping configuration for DKK
        attr_accessor :dkk
        # Tipping configuration for EUR
        attr_accessor :eur
        # Tipping configuration for GBP
        attr_accessor :gbp
        # Tipping configuration for GIP
        attr_accessor :gip
        # Tipping configuration for HKD
        attr_accessor :hkd
        # Tipping configuration for HUF
        attr_accessor :huf
        # Tipping configuration for JPY
        attr_accessor :jpy
        # Tipping configuration for MXN
        attr_accessor :mxn
        # Tipping configuration for MYR
        attr_accessor :myr
        # Tipping configuration for NOK
        attr_accessor :nok
        # Tipping configuration for NZD
        attr_accessor :nzd
        # Tipping configuration for PLN
        attr_accessor :pln
        # Tipping configuration for RON
        attr_accessor :ron
        # Tipping configuration for SEK
        attr_accessor :sek
        # Tipping configuration for SGD
        attr_accessor :sgd
        # Tipping configuration for USD
        attr_accessor :usd

        def initialize(
          aed: nil,
          aud: nil,
          bgn: nil,
          cad: nil,
          chf: nil,
          czk: nil,
          dkk: nil,
          eur: nil,
          gbp: nil,
          gip: nil,
          hkd: nil,
          huf: nil,
          jpy: nil,
          mxn: nil,
          myr: nil,
          nok: nil,
          nzd: nil,
          pln: nil,
          ron: nil,
          sek: nil,
          sgd: nil,
          usd: nil
        )
          @aed = aed
          @aud = aud
          @bgn = bgn
          @cad = cad
          @chf = chf
          @czk = czk
          @dkk = dkk
          @eur = eur
          @gbp = gbp
          @gip = gip
          @hkd = hkd
          @huf = huf
          @jpy = jpy
          @mxn = mxn
          @myr = myr
          @nok = nok
          @nzd = nzd
          @pln = pln
          @ron = ron
          @sek = sek
          @sgd = sgd
          @usd = usd
        end
      end

      class VerifoneP400 < ::Stripe::RequestParams
        # A File ID representing an image you want to display on the reader.
        attr_accessor :splashscreen

        def initialize(splashscreen: nil)
          @splashscreen = splashscreen
        end
      end

      class Wifi < ::Stripe::RequestParams
        class EnterpriseEapPeap < ::Stripe::RequestParams
          # A File ID representing a PEM file containing the server certificate
          attr_accessor :ca_certificate_file
          # Password for connecting to the WiFi network
          attr_accessor :password
          # Name of the WiFi network
          attr_accessor :ssid
          # Username for connecting to the WiFi network
          attr_accessor :username

          def initialize(ca_certificate_file: nil, password: nil, ssid: nil, username: nil)
            @ca_certificate_file = ca_certificate_file
            @password = password
            @ssid = ssid
            @username = username
          end
        end

        class EnterpriseEapTls < ::Stripe::RequestParams
          # A File ID representing a PEM file containing the server certificate
          attr_accessor :ca_certificate_file
          # A File ID representing a PEM file containing the client certificate
          attr_accessor :client_certificate_file
          # A File ID representing a PEM file containing the client RSA private key
          attr_accessor :private_key_file
          # Password for the private key file
          attr_accessor :private_key_file_password
          # Name of the WiFi network
          attr_accessor :ssid

          def initialize(
            ca_certificate_file: nil,
            client_certificate_file: nil,
            private_key_file: nil,
            private_key_file_password: nil,
            ssid: nil
          )
            @ca_certificate_file = ca_certificate_file
            @client_certificate_file = client_certificate_file
            @private_key_file = private_key_file
            @private_key_file_password = private_key_file_password
            @ssid = ssid
          end
        end

        class PersonalPsk < ::Stripe::RequestParams
          # Password for connecting to the WiFi network
          attr_accessor :password
          # Name of the WiFi network
          attr_accessor :ssid

          def initialize(password: nil, ssid: nil)
            @password = password
            @ssid = ssid
          end
        end
        # Credentials for a WPA-Enterprise WiFi network using the EAP-PEAP authentication method.
        attr_accessor :enterprise_eap_peap
        # Credentials for a WPA-Enterprise WiFi network using the EAP-TLS authentication method.
        attr_accessor :enterprise_eap_tls
        # Credentials for a WPA-Personal WiFi network.
        attr_accessor :personal_psk
        # Security type of the WiFi network. Fill out the hash with the corresponding name to provide the set of credentials for this security type.
        attr_accessor :type

        def initialize(
          enterprise_eap_peap: nil,
          enterprise_eap_tls: nil,
          personal_psk: nil,
          type: nil
        )
          @enterprise_eap_peap = enterprise_eap_peap
          @enterprise_eap_tls = enterprise_eap_tls
          @personal_psk = personal_psk
          @type = type
        end
      end
      # An object containing device type specific settings for BBPOS WisePad 3 readers.
      attr_accessor :bbpos_wisepad3
      # An object containing device type specific settings for BBPOS WisePOS E readers.
      attr_accessor :bbpos_wisepos_e
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Name of the configuration
      attr_accessor :name
      # Configurations for collecting transactions offline.
      attr_accessor :offline
      # Reboot time settings for readers. that support customized reboot time configuration.
      attr_accessor :reboot_window
      # An object containing device type specific settings for Stripe S700 readers.
      attr_accessor :stripe_s700
      # Tipping configurations for readers. supporting on-reader tips
      attr_accessor :tipping
      # An object containing device type specific settings for Verifone P400 readers.
      attr_accessor :verifone_p400
      # Configurations for connecting to a WiFi network.
      attr_accessor :wifi

      def initialize(
        bbpos_wisepad3: nil,
        bbpos_wisepos_e: nil,
        expand: nil,
        name: nil,
        offline: nil,
        reboot_window: nil,
        stripe_s700: nil,
        tipping: nil,
        verifone_p400: nil,
        wifi: nil
      )
        @bbpos_wisepad3 = bbpos_wisepad3
        @bbpos_wisepos_e = bbpos_wisepos_e
        @expand = expand
        @name = name
        @offline = offline
        @reboot_window = reboot_window
        @stripe_s700 = stripe_s700
        @tipping = tipping
        @verifone_p400 = verifone_p400
        @wifi = wifi
      end
    end
  end
end
