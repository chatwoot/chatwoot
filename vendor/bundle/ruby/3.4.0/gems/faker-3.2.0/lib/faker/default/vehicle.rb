# frozen_string_literal: true

module Faker
  class Vehicle < Base
    flexible :vehicle

    MILEAGE_MIN = 10_000
    MILEAGE_MAX = 90_000
    VIN_KEYSPACE = %w[A B C D E F G H J K L M N P R S T U V W X Y Z 0 1 2 3 4 5 6 7 8 9].freeze
    VIN_TRANSLITERATION = { A: 1, B: 2, C: 3, D: 4, E: 5, F: 6, G: 7, H: 8, J: 1, K: 2, L: 3, M: 4, N: 5, P: 7, R: 9, S: 2, T: 3, U: 4, V: 5, W: 6, X: 7, Y: 8, Z: 9 }.freeze
    VIN_WEIGHT = [8, 7, 6, 5, 4, 3, 2, 10, 0, 9, 8, 7, 6, 5, 4, 3, 2].freeze
    SG_CHECKSUM_WEIGHTS = [3, 14, 2, 12, 2, 11, 1].freeze
    SG_CHECKSUM_CHARS = 'AYUSPLJGDBZXTRMKHEC'

    class << self
      # Produces a random vehicle VIN number.
      #
      # @return [String]
      #
      # @example
      #   Faker::Vehicle.vin #=> "LLDWXZLG77VK2LUUF"
      #
      # @faker.version 1.6.4
      def vin
        front = 8.times.map { VIN_KEYSPACE.sample(random: Faker::Config.random) }.join
        back = 8.times.map { VIN_KEYSPACE.sample(random: Faker::Config.random) }.join
        checksum = "#{front}A#{back}".chars.each_with_index.map do |char, i|
          value = (char =~ /\A\d\z/ ? char.to_i : VIN_TRANSLITERATION[char.to_sym])
          value * VIN_WEIGHT[i]
        end.inject(:+) % 11
        checksum = 'X' if checksum == 10
        "#{front}#{checksum}#{back}"
      end

      # Produces a random vehicle manufacturer.
      #
      # @return [String]
      #
      # @example
      #   Faker::Vehicle.manufacture #=> "Lamborghini"
      #
      # @faker.version 1.6.4
      def manufacture
        fetch('vehicle.manufacture')
      end

      ##
      # Produces a random vehicle make.
      #
      # @return [String]
      #
      # @example
      #   Faker::Vehicle.make #=> "Honda"
      #
      # @faker.version 1.6.4
      def make
        fetch('vehicle.makes')
      end

      ##
      # Produces a random vehicle model.
      #
      # @param make_of_model [String] Specific valid vehicle make.
      # @return [String]
      #
      # @example
      #   Faker::Vehicle.model #=> "A8"
      #   Faker::Vehicle.model(make_of_model: 'Toyota') #=> "Prius"
      #
      # @faker.version 1.6.4
      def model(make_of_model: '')
        return fetch("vehicle.models_by_make.#{make}") if make_of_model.empty?

        fetch("vehicle.models_by_make.#{make_of_model}")
      end

      ##
      # Produces a random vehicle make and model.
      #
      # @return [String]
      #
      # @example
      #   Faker::Vehicle.make_and_model #=> "Dodge Charger"
      #
      # @faker.version 1.6.4
      def make_and_model
        m = make

        "#{m} #{model(make_of_model: m)}"
      end

      ##
      # Produces a random vehicle style.
      #
      # @return [String]
      #
      # @example
      #   Faker::Vehicle.style #=> "ESi"
      #
      # @faker.version 1.6.4
      def style
        fetch('vehicle.styles')
      end

      ##
      # Produces a random vehicle color.
      #
      # @return [String]
      #
      # @example
      #   Faker::Vehicle.color #=> "Red"
      #
      # @faker.version 1.6.4
      def color
        fetch('vehicle.colors')
      end

      ##
      # Produces a random vehicle transmission.
      #
      # @return [String]
      #
      # @example
      #   Faker::Vehicle.transmission #=> "Automanual"
      #
      # @faker.version 1.6.4
      def transmission
        fetch('vehicle.transmissions')
      end

      ##
      # Produces a random vehicle drive type.
      #
      # @return [String]
      #
      # @example
      #   Faker::Vehicle.drive_type #=> "4x2/2-wheel drive"
      #
      # @faker.version 1.6.4
      def drive_type
        fetch('vehicle.drive_types')
      end

      ##
      # Produces a random vehicle fuel type.
      #
      # @return [String]
      #
      # @example
      #   Faker::Vehicle.fuel_type #=> "Diesel"
      #
      # @faker.version 1.6.4
      def fuel_type
        fetch('vehicle.fuel_types')
      end

      ##
      # Produces a random car type.
      #
      # @return [String]
      #
      # @example
      #   Faker::Vehicle.car_type #=> "Sedan"
      #
      # @faker.version 1.6.4
      def car_type
        fetch('vehicle.car_types')
      end

      ##
      # Produces a random engine cylinder count.
      #
      # @return [String]
      #
      # @example
      #   Faker::Vehicle.engine_size #=> 6
      #   Faker::Vehicle.engine #=> 4
      #
      # @faker.version 1.6.4
      def engine
        "#{sample(fetch_all('vehicle.doors'))} #{fetch('vehicle.cylinder_engine')}"
      end

      alias engine_size engine

      ##
      # Produces a random list of car options.
      #
      # @return [Array<String>]
      #
      # @example
      #   Faker::Vehicle.car_options #=> ["DVD System", "MP3 (Single Disc)", "Tow Package", "CD (Multi Disc)", "Cassette Player", "Bucket Seats", "Cassette Player", "Leather Interior", "AM/FM Stereo", "Third Row Seats"]
      #
      # @faker.version 1.6.4
      def car_options
        Array.new(rand(5...10)) { fetch('vehicle.car_options') }
      end

      ##
      # Produces a random list of standard specs.
      #
      # @return [Array<String>]
      #
      # @example
      #   Faker::Vehicle.standard_specs #=> ["Full-size spare tire w/aluminum alloy wheel", "Back-up camera", "Carpeted cargo area", "Silver accent IP trim finisher -inc: silver shifter finisher", "Back-up camera", "Water-repellent windshield & front door glass", "Floor carpeting"]
      #
      # @faker.version 1.6.4
      def standard_specs
        Array.new(rand(5...10)) { fetch('vehicle.standard_specs') }
      end

      ##
      # Produces a random vehicle door count.
      #
      # @return [Integer]
      #
      # @example
      #   Faker::Vehicle.doors #=> 1
      #   Faker::Vehicle.door_count #=> 3
      #
      # @faker.version 1.6.4
      def doors
        sample(fetch_all('vehicle.doors'))
      end
      alias door_count doors

      ##
      # Produces a random car year between 1 and 15 years ago.
      #
      # @return [Integer]
      #
      # @example
      #   Faker::Vehicle.year #=> 2008
      #
      # @faker.version 1.6.4
      def year
        Faker::Time.backward(days: rand_in_range(365, 5475), period: :all, format: '%Y').to_i
      end

      ##
      # Produces a random mileage/kilometrage for a vehicle.
      #
      # @param min [Integer] Specific minimum limit for mileage generation.
      # @param max [Integer] Specific maximum limit for mileage generation.
      # @return [Integer]
      #
      # @example
      #   Faker::Vehicle.mileage #=> 26961
      #   Faker::Vehicle.mileage(min: 50_000) #=> 81557
      #   Faker::Vehicle.mileage(min: 50_000, max: 250_000) #=> 117503
      #   Faker::Vehicle.kilometrage #=> 35378
      #
      # @faker.version 1.6.4
      def mileage(min: MILEAGE_MIN, max: MILEAGE_MAX)
        rand_in_range(min, max)
      end

      alias kilometrage mileage

      ##
      # Produces a random license plate number.
      #
      # @param state_abbreviation [String] Two letter state abbreviation for license plate generation.
      # @return [String]
      #
      # @example
      #   Faker::Vehicle.license_plate #=> "DEP-2483"
      #   Faker::Vehicle.license_plate(state_abbreviation: 'FL') #=> "977 UNU"
      #
      # @faker.version 1.6.4
      def license_plate(state_abbreviation: '')
        return regexify(bothify(fetch('vehicle.license_plate'))) if state_abbreviation.empty?

        key = "vehicle.license_plate_by_state.#{state_abbreviation}"
        regexify(bothify(fetch(key)))
      end

      ##
      # Produces a random license plate number for Singapore.
      #
      # @return [String]
      #
      # @example
      #   Faker::Vehicle.singapore_license_plate #=> "SLV1854M"
      #
      # @faker.version 1.6.4
      def singapore_license_plate
        key = 'vehicle.license_plate'
        plate_number = regexify(bothify(fetch(key)))
        "#{plate_number}#{singapore_checksum(plate_number)}"
      end

      ##
      # Produces a car version
      #
      # @return [String]
      #
      # @example
      #  Faker::Vehicle.version #=> "40 TFSI Premium"
      #
      # @faker.version next
      def version
        fetch('vehicle.version')
      end

      private

      def singapore_checksum(plate_number)
        padded_alphabets = format('%3s', plate_number[/^[A-Z]+/]).tr(' ', '-').chars
        padded_digits = format('%04d', plate_number[/\d+/]).chars.map(&:to_i)
        sum = [*padded_alphabets, *padded_digits].each_with_index.reduce(0) do |memo, (char, i)|
          value = char.is_a?(Integer) ? char : char.ord - 64
          memo + (SG_CHECKSUM_WEIGHTS[i] * value)
        end

        SG_CHECKSUM_CHARS.chars[sum % 19]
      end
    end
  end
end
