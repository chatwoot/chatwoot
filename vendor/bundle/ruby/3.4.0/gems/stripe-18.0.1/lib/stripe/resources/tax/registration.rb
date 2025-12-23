# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Tax
    # A Tax `Registration` lets us know that your business is registered to collect tax on payments within a region, enabling you to [automatically collect tax](https://stripe.com/docs/tax).
    #
    # Stripe doesn't register on your behalf with the relevant authorities when you create a Tax `Registration` object. For more information on how to register to collect tax, see [our guide](https://stripe.com/docs/tax/registering).
    #
    # Related guide: [Using the Registrations API](https://stripe.com/docs/tax/registrations-api)
    class Registration < APIResource
      extend Stripe::APIOperations::Create
      extend Stripe::APIOperations::List
      include Stripe::APIOperations::Save

      OBJECT_NAME = "tax.registration"
      def self.object_name
        "tax.registration"
      end

      class CountryOptions < ::Stripe::StripeObject
        class Ae < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an Default standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Al < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Am < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Ao < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class At < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an EU standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in an EU country.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Au < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an Default standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Aw < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Az < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Ba < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Bb < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Bd < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Be < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an EU standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in an EU country.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Bf < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Bg < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an EU standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in an EU country.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Bh < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Bj < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Bs < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class By < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Ca < ::Stripe::StripeObject
          class ProvinceStandard < ::Stripe::StripeObject
            # Two-letter CA province code ([ISO 3166-2](https://en.wikipedia.org/wiki/ISO_3166-2)).
            attr_reader :province

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field province_standard
          attr_reader :province_standard
          # Type of registration in Canada.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { province_standard: ProvinceStandard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Cd < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Ch < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an Default standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Cl < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Cm < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Co < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Cr < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Cv < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Cy < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an EU standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in an EU country.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Cz < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an EU standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in an EU country.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class De < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an EU standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in an EU country.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Dk < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an EU standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in an EU country.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Ec < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Ee < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an EU standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in an EU country.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Eg < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Es < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an EU standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in an EU country.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Et < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Fi < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an EU standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in an EU country.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Fr < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an EU standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in an EU country.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Gb < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an Default standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Ge < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Gn < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Gr < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an EU standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in an EU country.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Hr < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an EU standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in an EU country.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Hu < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an EU standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in an EU country.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Id < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Ie < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an EU standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in an EU country.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class In < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Is < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class It < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an EU standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in an EU country.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Jp < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an Default standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Ke < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Kg < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Kh < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Kr < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Kz < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class La < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Lt < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an EU standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in an EU country.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Lu < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an EU standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in an EU country.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Lv < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an EU standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in an EU country.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Ma < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Md < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Me < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Mk < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Mr < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Mt < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an EU standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in an EU country.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Mx < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class My < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Ng < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Nl < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an EU standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in an EU country.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class No < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an Default standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Np < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Nz < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an Default standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Om < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Pe < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Ph < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Pl < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an EU standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in an EU country.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Pt < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an EU standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in an EU country.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Ro < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an EU standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in an EU country.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Rs < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Ru < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Sa < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Se < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an EU standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in an EU country.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Sg < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an Default standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Si < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an EU standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in an EU country.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Sk < ::Stripe::StripeObject
          class Standard < ::Stripe::StripeObject
            # Place of supply scheme used in an EU standard registration.
            attr_reader :place_of_supply_scheme

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field standard
          attr_reader :standard
          # Type of registration in an EU country.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { standard: Standard }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Sn < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Sr < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Th < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Tj < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Tr < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Tw < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Tz < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Ua < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Ug < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Us < ::Stripe::StripeObject
          class LocalAmusementTax < ::Stripe::StripeObject
            # A [FIPS code](https://www.census.gov/library/reference/code-lists/ansi.html) representing the local jurisdiction.
            attr_reader :jurisdiction

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end

          class LocalLeaseTax < ::Stripe::StripeObject
            # A [FIPS code](https://www.census.gov/library/reference/code-lists/ansi.html) representing the local jurisdiction.
            attr_reader :jurisdiction

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end

          class StateSalesTax < ::Stripe::StripeObject
            class Election < ::Stripe::StripeObject
              # A [FIPS code](https://www.census.gov/library/reference/code-lists/ansi.html) representing the local jurisdiction.
              attr_reader :jurisdiction
              # The type of the election for the state sales tax registration.
              attr_reader :type

              def self.inner_class_types
                @inner_class_types = {}
              end

              def self.field_remappings
                @field_remappings = {}
              end
            end
            # Elections for the state sales tax registration.
            attr_reader :elections

            def self.inner_class_types
              @inner_class_types = { elections: Election }
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field local_amusement_tax
          attr_reader :local_amusement_tax
          # Attribute for field local_lease_tax
          attr_reader :local_lease_tax
          # Two-letter US state code ([ISO 3166-2](https://en.wikipedia.org/wiki/ISO_3166-2)).
          attr_reader :state
          # Attribute for field state_sales_tax
          attr_reader :state_sales_tax
          # Type of registration in the US.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {
              local_amusement_tax: LocalAmusementTax,
              local_lease_tax: LocalLeaseTax,
              state_sales_tax: StateSalesTax,
            }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Uy < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Uz < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Vn < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Za < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Zm < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Zw < ::Stripe::StripeObject
          # Type of registration in `country`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Attribute for field ae
        attr_reader :ae
        # Attribute for field al
        attr_reader :al
        # Attribute for field am
        attr_reader :am
        # Attribute for field ao
        attr_reader :ao
        # Attribute for field at
        attr_reader :at
        # Attribute for field au
        attr_reader :au
        # Attribute for field aw
        attr_reader :aw
        # Attribute for field az
        attr_reader :az
        # Attribute for field ba
        attr_reader :ba
        # Attribute for field bb
        attr_reader :bb
        # Attribute for field bd
        attr_reader :bd
        # Attribute for field be
        attr_reader :be
        # Attribute for field bf
        attr_reader :bf
        # Attribute for field bg
        attr_reader :bg
        # Attribute for field bh
        attr_reader :bh
        # Attribute for field bj
        attr_reader :bj
        # Attribute for field bs
        attr_reader :bs
        # Attribute for field by
        attr_reader :by
        # Attribute for field ca
        attr_reader :ca
        # Attribute for field cd
        attr_reader :cd
        # Attribute for field ch
        attr_reader :ch
        # Attribute for field cl
        attr_reader :cl
        # Attribute for field cm
        attr_reader :cm
        # Attribute for field co
        attr_reader :co
        # Attribute for field cr
        attr_reader :cr
        # Attribute for field cv
        attr_reader :cv
        # Attribute for field cy
        attr_reader :cy
        # Attribute for field cz
        attr_reader :cz
        # Attribute for field de
        attr_reader :de
        # Attribute for field dk
        attr_reader :dk
        # Attribute for field ec
        attr_reader :ec
        # Attribute for field ee
        attr_reader :ee
        # Attribute for field eg
        attr_reader :eg
        # Attribute for field es
        attr_reader :es
        # Attribute for field et
        attr_reader :et
        # Attribute for field fi
        attr_reader :fi
        # Attribute for field fr
        attr_reader :fr
        # Attribute for field gb
        attr_reader :gb
        # Attribute for field ge
        attr_reader :ge
        # Attribute for field gn
        attr_reader :gn
        # Attribute for field gr
        attr_reader :gr
        # Attribute for field hr
        attr_reader :hr
        # Attribute for field hu
        attr_reader :hu
        # Attribute for field id
        attr_reader :id
        # Attribute for field ie
        attr_reader :ie
        # Attribute for field in
        attr_reader :in
        # Attribute for field is
        attr_reader :is
        # Attribute for field it
        attr_reader :it
        # Attribute for field jp
        attr_reader :jp
        # Attribute for field ke
        attr_reader :ke
        # Attribute for field kg
        attr_reader :kg
        # Attribute for field kh
        attr_reader :kh
        # Attribute for field kr
        attr_reader :kr
        # Attribute for field kz
        attr_reader :kz
        # Attribute for field la
        attr_reader :la
        # Attribute for field lt
        attr_reader :lt
        # Attribute for field lu
        attr_reader :lu
        # Attribute for field lv
        attr_reader :lv
        # Attribute for field ma
        attr_reader :ma
        # Attribute for field md
        attr_reader :md
        # Attribute for field me
        attr_reader :me
        # Attribute for field mk
        attr_reader :mk
        # Attribute for field mr
        attr_reader :mr
        # Attribute for field mt
        attr_reader :mt
        # Attribute for field mx
        attr_reader :mx
        # Attribute for field my
        attr_reader :my
        # Attribute for field ng
        attr_reader :ng
        # Attribute for field nl
        attr_reader :nl
        # Attribute for field no
        attr_reader :no
        # Attribute for field np
        attr_reader :np
        # Attribute for field nz
        attr_reader :nz
        # Attribute for field om
        attr_reader :om
        # Attribute for field pe
        attr_reader :pe
        # Attribute for field ph
        attr_reader :ph
        # Attribute for field pl
        attr_reader :pl
        # Attribute for field pt
        attr_reader :pt
        # Attribute for field ro
        attr_reader :ro
        # Attribute for field rs
        attr_reader :rs
        # Attribute for field ru
        attr_reader :ru
        # Attribute for field sa
        attr_reader :sa
        # Attribute for field se
        attr_reader :se
        # Attribute for field sg
        attr_reader :sg
        # Attribute for field si
        attr_reader :si
        # Attribute for field sk
        attr_reader :sk
        # Attribute for field sn
        attr_reader :sn
        # Attribute for field sr
        attr_reader :sr
        # Attribute for field th
        attr_reader :th
        # Attribute for field tj
        attr_reader :tj
        # Attribute for field tr
        attr_reader :tr
        # Attribute for field tw
        attr_reader :tw
        # Attribute for field tz
        attr_reader :tz
        # Attribute for field ua
        attr_reader :ua
        # Attribute for field ug
        attr_reader :ug
        # Attribute for field us
        attr_reader :us
        # Attribute for field uy
        attr_reader :uy
        # Attribute for field uz
        attr_reader :uz
        # Attribute for field vn
        attr_reader :vn
        # Attribute for field za
        attr_reader :za
        # Attribute for field zm
        attr_reader :zm
        # Attribute for field zw
        attr_reader :zw

        def self.inner_class_types
          @inner_class_types = {
            ae: Ae,
            al: Al,
            am: Am,
            ao: Ao,
            at: At,
            au: Au,
            aw: Aw,
            az: Az,
            ba: Ba,
            bb: Bb,
            bd: Bd,
            be: Be,
            bf: Bf,
            bg: Bg,
            bh: Bh,
            bj: Bj,
            bs: Bs,
            by: By,
            ca: Ca,
            cd: Cd,
            ch: Ch,
            cl: Cl,
            cm: Cm,
            co: Co,
            cr: Cr,
            cv: Cv,
            cy: Cy,
            cz: Cz,
            de: De,
            dk: Dk,
            ec: Ec,
            ee: Ee,
            eg: Eg,
            es: Es,
            et: Et,
            fi: Fi,
            fr: Fr,
            gb: Gb,
            ge: Ge,
            gn: Gn,
            gr: Gr,
            hr: Hr,
            hu: Hu,
            id: Id,
            ie: Ie,
            in: In,
            is: Is,
            it: It,
            jp: Jp,
            ke: Ke,
            kg: Kg,
            kh: Kh,
            kr: Kr,
            kz: Kz,
            la: La,
            lt: Lt,
            lu: Lu,
            lv: Lv,
            ma: Ma,
            md: Md,
            me: Me,
            mk: Mk,
            mr: Mr,
            mt: Mt,
            mx: Mx,
            my: My,
            ng: Ng,
            nl: Nl,
            no: No,
            np: Np,
            nz: Nz,
            om: Om,
            pe: Pe,
            ph: Ph,
            pl: Pl,
            pt: Pt,
            ro: Ro,
            rs: Rs,
            ru: Ru,
            sa: Sa,
            se: Se,
            sg: Sg,
            si: Si,
            sk: Sk,
            sn: Sn,
            sr: Sr,
            th: Th,
            tj: Tj,
            tr: Tr,
            tw: Tw,
            tz: Tz,
            ua: Ua,
            ug: Ug,
            us: Us,
            uy: Uy,
            uz: Uz,
            vn: Vn,
            za: Za,
            zm: Zm,
            zw: Zw,
          }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Time at which the registration becomes active. Measured in seconds since the Unix epoch.
      attr_reader :active_from
      # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
      attr_reader :country
      # Attribute for field country_options
      attr_reader :country_options
      # Time at which the object was created. Measured in seconds since the Unix epoch.
      attr_reader :created
      # If set, the registration stops being active at this time. If not set, the registration will be active indefinitely. Measured in seconds since the Unix epoch.
      attr_reader :expires_at
      # Unique identifier for the object.
      attr_reader :id
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # The status of the registration. This field is present for convenience and can be deduced from `active_from` and `expires_at`.
      attr_reader :status

      # Creates a new Tax Registration object.
      def self.create(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: "/v1/tax/registrations",
          params: params,
          opts: opts
        )
      end

      # Returns a list of Tax Registration objects.
      def self.list(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: "/v1/tax/registrations",
          params: params,
          opts: opts
        )
      end

      # Updates an existing Tax Registration object.
      #
      # A registration cannot be deleted after it has been created. If you wish to end a registration you may do so by setting expires_at.
      def self.update(id, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/tax/registrations/%<id>s", { id: CGI.escape(id) }),
          params: params,
          opts: opts
        )
      end

      def self.inner_class_types
        @inner_class_types = { country_options: CountryOptions }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
