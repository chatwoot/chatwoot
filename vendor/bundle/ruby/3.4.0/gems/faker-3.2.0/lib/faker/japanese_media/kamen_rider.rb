# frozen_string_literal: true

module Faker
  class JapaneseMedia
    class KamenRider < Base
      class << self
        ERAS = %i[showa heisei reiwa].freeze

        def eras=(new_eras)
          selected_eras = ERAS & new_eras
          @eras = selected_eras.empty? ? ERAS : selected_eras
        end

        ##
        # Produces the name of a Kamen Rider from a series in the given era.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::KamenRider.kamen_rider #=> "Kamen Rider Revice"
        #
        # @faker.version next
        def kamen_rider(*eras)
          from_eras(*eras, field: :kamen_riders)
        end

        ##
        # Produces the name of a main user of Kamen Rider.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::KamenRider.user #=> "Ikki Igarashi"
        #
        # @faker.version next
        def user(*eras)
          from_eras(*eras, field: :users)
        end

        ##
        # Produces the name of a Kamen Rider series.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::KamenRider.series #=> "Kamen Rider Revice"
        #
        # @faker.version next
        def series(*eras)
          from_eras(*eras, field: :series)
        end

        ##
        # Produces the name of a collectible device from a Kamen Rider series.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::KamenRider.collectible_device #=> "Vistamp"
        #
        # @faker.version next
        def collectible_device(*eras)
          from_eras(*eras, field: :collectible_devices) { |e| e.delete(:showa) }
        end

        # Produces the name of a transformation device used by a Kamen Rider
        # from the given eras.
        #
        # @return [String]
        #
        # @example Faker::JapaneseMedia::KamenRider.transformation_device #=>
        # "Revice Driver"
        #
        # @faker.version next
        def transformation_device(*eras)
          from_eras(*eras, field: :transformation_devices)
        end

        private

        def eras
          @eras ||= ERAS
        end

        def from_eras(*input_eras, field:)
          selected_eras = (ERAS & input_eras).then do |selected|
            selected.empty? ? eras : selected
          end.dup
          yield(selected_eras) if block_given?

          raise UnavailableInEra, "#{field} is unavailable in the selected eras." if selected_eras.empty?

          selected_eras.sample.then do |era|
            fetch("kamen_rider.#{era}.#{field}")
          end
        end

        class UnavailableInEra < StandardError; end
      end
    end
  end
end
