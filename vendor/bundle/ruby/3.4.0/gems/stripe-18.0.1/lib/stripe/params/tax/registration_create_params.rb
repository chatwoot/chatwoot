# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Tax
    class RegistrationCreateParams < ::Stripe::RequestParams
      class CountryOptions < ::Stripe::RequestParams
        class Ae < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Al < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Am < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Ao < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class At < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an EU standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in an EU country.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Au < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Aw < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Az < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Ba < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Bb < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Bd < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Be < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an EU standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in an EU country.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Bf < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Bg < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an EU standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in an EU country.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Bh < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Bj < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Bs < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class By < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Ca < ::Stripe::RequestParams
          class ProvinceStandard < ::Stripe::RequestParams
            # Two-letter CA province code ([ISO 3166-2](https://en.wikipedia.org/wiki/ISO_3166-2)).
            attr_accessor :province

            def initialize(province: nil)
              @province = province
            end
          end
          # Options for the provincial tax registration.
          attr_accessor :province_standard
          # Type of registration to be created in Canada.
          attr_accessor :type

          def initialize(province_standard: nil, type: nil)
            @province_standard = province_standard
            @type = type
          end
        end

        class Cd < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Ch < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Cl < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Cm < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Co < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Cr < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Cv < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Cy < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an EU standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in an EU country.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Cz < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an EU standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in an EU country.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class De < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an EU standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in an EU country.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Dk < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an EU standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in an EU country.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Ec < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Ee < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an EU standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in an EU country.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Eg < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Es < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an EU standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in an EU country.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Et < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Fi < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an EU standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in an EU country.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Fr < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an EU standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in an EU country.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Gb < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Ge < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Gn < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Gr < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an EU standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in an EU country.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Hr < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an EU standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in an EU country.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Hu < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an EU standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in an EU country.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Id < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Ie < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an EU standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in an EU country.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class In < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Is < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class It < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an EU standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in an EU country.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Jp < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Ke < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Kg < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Kh < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Kr < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Kz < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class La < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Lt < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an EU standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in an EU country.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Lu < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an EU standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in an EU country.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Lv < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an EU standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in an EU country.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Ma < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Md < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Me < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Mk < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Mr < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Mt < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an EU standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in an EU country.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Mx < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class My < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Ng < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Nl < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an EU standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in an EU country.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class No < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Np < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Nz < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Om < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Pe < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Ph < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Pl < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an EU standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in an EU country.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Pt < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an EU standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in an EU country.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Ro < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an EU standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in an EU country.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Rs < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Ru < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Sa < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Se < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an EU standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in an EU country.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Sg < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Si < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an EU standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in an EU country.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Sk < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an EU standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in an EU country.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Sn < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Sr < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Th < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Tj < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Tr < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Tw < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Tz < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Ua < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Ug < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Us < ::Stripe::RequestParams
          class LocalAmusementTax < ::Stripe::RequestParams
            # A [FIPS code](https://www.census.gov/library/reference/code-lists/ansi.html) representing the local jurisdiction. Supported FIPS codes are: `14000` (Chicago), `02154` (Arlington Heights), `06613` (Bloomington), `10906` (Campton Hills), `21696` (East Dundee), `24582` (Evanston), `45421` (Lynwood), `48892` (Midlothian), `64343` (River Grove), and `68081` (Schiller Park).
            attr_accessor :jurisdiction

            def initialize(jurisdiction: nil)
              @jurisdiction = jurisdiction
            end
          end

          class LocalLeaseTax < ::Stripe::RequestParams
            # A [FIPS code](https://www.census.gov/library/reference/code-lists/ansi.html) representing the local jurisdiction. Supported FIPS codes are: `14000` (Chicago).
            attr_accessor :jurisdiction

            def initialize(jurisdiction: nil)
              @jurisdiction = jurisdiction
            end
          end

          class StateSalesTax < ::Stripe::RequestParams
            class Election < ::Stripe::RequestParams
              # A [FIPS code](https://www.census.gov/library/reference/code-lists/ansi.html) representing the local jurisdiction. Supported FIPS codes are: `003` (Allegheny County) and `60000` (Philadelphia City).
              attr_accessor :jurisdiction
              # The type of the election for the state sales tax registration.
              attr_accessor :type

              def initialize(jurisdiction: nil, type: nil)
                @jurisdiction = jurisdiction
                @type = type
              end
            end
            # Elections for the state sales tax registration.
            attr_accessor :elections

            def initialize(elections: nil)
              @elections = elections
            end
          end
          # Options for the local amusement tax registration.
          attr_accessor :local_amusement_tax
          # Options for the local lease tax registration.
          attr_accessor :local_lease_tax
          # Two-letter US state code ([ISO 3166-2](https://en.wikipedia.org/wiki/ISO_3166-2)).
          attr_accessor :state
          # Options for the state sales tax registration.
          attr_accessor :state_sales_tax
          # Type of registration to be created in the US.
          attr_accessor :type

          def initialize(
            local_amusement_tax: nil,
            local_lease_tax: nil,
            state: nil,
            state_sales_tax: nil,
            type: nil
          )
            @local_amusement_tax = local_amusement_tax
            @local_lease_tax = local_lease_tax
            @state = state
            @state_sales_tax = state_sales_tax
            @type = type
          end
        end

        class Uy < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Uz < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Vn < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Za < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end

        class Zm < ::Stripe::RequestParams
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(type: nil)
            @type = type
          end
        end

        class Zw < ::Stripe::RequestParams
          class Standard < ::Stripe::RequestParams
            # Place of supply scheme used in an standard registration.
            attr_accessor :place_of_supply_scheme

            def initialize(place_of_supply_scheme: nil)
              @place_of_supply_scheme = place_of_supply_scheme
            end
          end
          # Options for the standard registration.
          attr_accessor :standard
          # Type of registration to be created in `country`.
          attr_accessor :type

          def initialize(standard: nil, type: nil)
            @standard = standard
            @type = type
          end
        end
        # Options for the registration in AE.
        attr_accessor :ae
        # Options for the registration in AL.
        attr_accessor :al
        # Options for the registration in AM.
        attr_accessor :am
        # Options for the registration in AO.
        attr_accessor :ao
        # Options for the registration in AT.
        attr_accessor :at
        # Options for the registration in AU.
        attr_accessor :au
        # Options for the registration in AW.
        attr_accessor :aw
        # Options for the registration in AZ.
        attr_accessor :az
        # Options for the registration in BA.
        attr_accessor :ba
        # Options for the registration in BB.
        attr_accessor :bb
        # Options for the registration in BD.
        attr_accessor :bd
        # Options for the registration in BE.
        attr_accessor :be
        # Options for the registration in BF.
        attr_accessor :bf
        # Options for the registration in BG.
        attr_accessor :bg
        # Options for the registration in BH.
        attr_accessor :bh
        # Options for the registration in BJ.
        attr_accessor :bj
        # Options for the registration in BS.
        attr_accessor :bs
        # Options for the registration in BY.
        attr_accessor :by
        # Options for the registration in CA.
        attr_accessor :ca
        # Options for the registration in CD.
        attr_accessor :cd
        # Options for the registration in CH.
        attr_accessor :ch
        # Options for the registration in CL.
        attr_accessor :cl
        # Options for the registration in CM.
        attr_accessor :cm
        # Options for the registration in CO.
        attr_accessor :co
        # Options for the registration in CR.
        attr_accessor :cr
        # Options for the registration in CV.
        attr_accessor :cv
        # Options for the registration in CY.
        attr_accessor :cy
        # Options for the registration in CZ.
        attr_accessor :cz
        # Options for the registration in DE.
        attr_accessor :de
        # Options for the registration in DK.
        attr_accessor :dk
        # Options for the registration in EC.
        attr_accessor :ec
        # Options for the registration in EE.
        attr_accessor :ee
        # Options for the registration in EG.
        attr_accessor :eg
        # Options for the registration in ES.
        attr_accessor :es
        # Options for the registration in ET.
        attr_accessor :et
        # Options for the registration in FI.
        attr_accessor :fi
        # Options for the registration in FR.
        attr_accessor :fr
        # Options for the registration in GB.
        attr_accessor :gb
        # Options for the registration in GE.
        attr_accessor :ge
        # Options for the registration in GN.
        attr_accessor :gn
        # Options for the registration in GR.
        attr_accessor :gr
        # Options for the registration in HR.
        attr_accessor :hr
        # Options for the registration in HU.
        attr_accessor :hu
        # Options for the registration in ID.
        attr_accessor :id
        # Options for the registration in IE.
        attr_accessor :ie
        # Options for the registration in IN.
        attr_accessor :in
        # Options for the registration in IS.
        attr_accessor :is
        # Options for the registration in IT.
        attr_accessor :it
        # Options for the registration in JP.
        attr_accessor :jp
        # Options for the registration in KE.
        attr_accessor :ke
        # Options for the registration in KG.
        attr_accessor :kg
        # Options for the registration in KH.
        attr_accessor :kh
        # Options for the registration in KR.
        attr_accessor :kr
        # Options for the registration in KZ.
        attr_accessor :kz
        # Options for the registration in LA.
        attr_accessor :la
        # Options for the registration in LT.
        attr_accessor :lt
        # Options for the registration in LU.
        attr_accessor :lu
        # Options for the registration in LV.
        attr_accessor :lv
        # Options for the registration in MA.
        attr_accessor :ma
        # Options for the registration in MD.
        attr_accessor :md
        # Options for the registration in ME.
        attr_accessor :me
        # Options for the registration in MK.
        attr_accessor :mk
        # Options for the registration in MR.
        attr_accessor :mr
        # Options for the registration in MT.
        attr_accessor :mt
        # Options for the registration in MX.
        attr_accessor :mx
        # Options for the registration in MY.
        attr_accessor :my
        # Options for the registration in NG.
        attr_accessor :ng
        # Options for the registration in NL.
        attr_accessor :nl
        # Options for the registration in NO.
        attr_accessor :no
        # Options for the registration in NP.
        attr_accessor :np
        # Options for the registration in NZ.
        attr_accessor :nz
        # Options for the registration in OM.
        attr_accessor :om
        # Options for the registration in PE.
        attr_accessor :pe
        # Options for the registration in PH.
        attr_accessor :ph
        # Options for the registration in PL.
        attr_accessor :pl
        # Options for the registration in PT.
        attr_accessor :pt
        # Options for the registration in RO.
        attr_accessor :ro
        # Options for the registration in RS.
        attr_accessor :rs
        # Options for the registration in RU.
        attr_accessor :ru
        # Options for the registration in SA.
        attr_accessor :sa
        # Options for the registration in SE.
        attr_accessor :se
        # Options for the registration in SG.
        attr_accessor :sg
        # Options for the registration in SI.
        attr_accessor :si
        # Options for the registration in SK.
        attr_accessor :sk
        # Options for the registration in SN.
        attr_accessor :sn
        # Options for the registration in SR.
        attr_accessor :sr
        # Options for the registration in TH.
        attr_accessor :th
        # Options for the registration in TJ.
        attr_accessor :tj
        # Options for the registration in TR.
        attr_accessor :tr
        # Options for the registration in TW.
        attr_accessor :tw
        # Options for the registration in TZ.
        attr_accessor :tz
        # Options for the registration in UA.
        attr_accessor :ua
        # Options for the registration in UG.
        attr_accessor :ug
        # Options for the registration in US.
        attr_accessor :us
        # Options for the registration in UY.
        attr_accessor :uy
        # Options for the registration in UZ.
        attr_accessor :uz
        # Options for the registration in VN.
        attr_accessor :vn
        # Options for the registration in ZA.
        attr_accessor :za
        # Options for the registration in ZM.
        attr_accessor :zm
        # Options for the registration in ZW.
        attr_accessor :zw

        def initialize(
          ae: nil,
          al: nil,
          am: nil,
          ao: nil,
          at: nil,
          au: nil,
          aw: nil,
          az: nil,
          ba: nil,
          bb: nil,
          bd: nil,
          be: nil,
          bf: nil,
          bg: nil,
          bh: nil,
          bj: nil,
          bs: nil,
          by: nil,
          ca: nil,
          cd: nil,
          ch: nil,
          cl: nil,
          cm: nil,
          co: nil,
          cr: nil,
          cv: nil,
          cy: nil,
          cz: nil,
          de: nil,
          dk: nil,
          ec: nil,
          ee: nil,
          eg: nil,
          es: nil,
          et: nil,
          fi: nil,
          fr: nil,
          gb: nil,
          ge: nil,
          gn: nil,
          gr: nil,
          hr: nil,
          hu: nil,
          id: nil,
          ie: nil,
          in_: nil,
          is: nil,
          it: nil,
          jp: nil,
          ke: nil,
          kg: nil,
          kh: nil,
          kr: nil,
          kz: nil,
          la: nil,
          lt: nil,
          lu: nil,
          lv: nil,
          ma: nil,
          md: nil,
          me: nil,
          mk: nil,
          mr: nil,
          mt: nil,
          mx: nil,
          my: nil,
          ng: nil,
          nl: nil,
          no: nil,
          np: nil,
          nz: nil,
          om: nil,
          pe: nil,
          ph: nil,
          pl: nil,
          pt: nil,
          ro: nil,
          rs: nil,
          ru: nil,
          sa: nil,
          se: nil,
          sg: nil,
          si: nil,
          sk: nil,
          sn: nil,
          sr: nil,
          th: nil,
          tj: nil,
          tr: nil,
          tw: nil,
          tz: nil,
          ua: nil,
          ug: nil,
          us: nil,
          uy: nil,
          uz: nil,
          vn: nil,
          za: nil,
          zm: nil,
          zw: nil
        )
          @ae = ae
          @al = al
          @am = am
          @ao = ao
          @at = at
          @au = au
          @aw = aw
          @az = az
          @ba = ba
          @bb = bb
          @bd = bd
          @be = be
          @bf = bf
          @bg = bg
          @bh = bh
          @bj = bj
          @bs = bs
          @by = by
          @ca = ca
          @cd = cd
          @ch = ch
          @cl = cl
          @cm = cm
          @co = co
          @cr = cr
          @cv = cv
          @cy = cy
          @cz = cz
          @de = de
          @dk = dk
          @ec = ec
          @ee = ee
          @eg = eg
          @es = es
          @et = et
          @fi = fi
          @fr = fr
          @gb = gb
          @ge = ge
          @gn = gn
          @gr = gr
          @hr = hr
          @hu = hu
          @id = id
          @ie = ie
          @in = in_
          @is = is
          @it = it
          @jp = jp
          @ke = ke
          @kg = kg
          @kh = kh
          @kr = kr
          @kz = kz
          @la = la
          @lt = lt
          @lu = lu
          @lv = lv
          @ma = ma
          @md = md
          @me = me
          @mk = mk
          @mr = mr
          @mt = mt
          @mx = mx
          @my = my
          @ng = ng
          @nl = nl
          @no = no
          @np = np
          @nz = nz
          @om = om
          @pe = pe
          @ph = ph
          @pl = pl
          @pt = pt
          @ro = ro
          @rs = rs
          @ru = ru
          @sa = sa
          @se = se
          @sg = sg
          @si = si
          @sk = sk
          @sn = sn
          @sr = sr
          @th = th
          @tj = tj
          @tr = tr
          @tw = tw
          @tz = tz
          @ua = ua
          @ug = ug
          @us = us
          @uy = uy
          @uz = uz
          @vn = vn
          @za = za
          @zm = zm
          @zw = zw
        end
      end
      # Time at which the Tax Registration becomes active. It can be either `now` to indicate the current time, or a future timestamp measured in seconds since the Unix epoch.
      attr_accessor :active_from
      # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
      attr_accessor :country
      # Specific options for a registration in the specified `country`.
      attr_accessor :country_options
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # If set, the Tax Registration stops being active at this time. If not set, the Tax Registration will be active indefinitely. Timestamp measured in seconds since the Unix epoch.
      attr_accessor :expires_at

      def initialize(
        active_from: nil,
        country: nil,
        country_options: nil,
        expand: nil,
        expires_at: nil
      )
        @active_from = active_from
        @country = country
        @country_options = country_options
        @expand = expand
        @expires_at = expires_at
      end
    end
  end
end
