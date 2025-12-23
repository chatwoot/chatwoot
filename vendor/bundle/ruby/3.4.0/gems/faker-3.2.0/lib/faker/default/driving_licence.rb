# frozen_string_literal: true

module Faker
  class DrivingLicence < Base
    GB_PADDING = '9999'
    NI_CHANCE = 0.03 # NI Pop is about 3% of total UK population

    class << self
      ##
      # Produces a random British driving licence number.
      #
      # @param last_name [String] The last name of the driving licence's owner.
      # @param initials [String] The initials of the driving licence's owner.
      # @param gender [String] The gender of the driving licence's owner.
      # @param date_of_birth [String] The date of birth of the driving licence's owner.
      # @return [String]
      #
      # @example
      #   Faker::DrivingLicence.british_driving_licence        #=> "MCDER712081VF7EK"
      #   Faker::DrivingLicence.british_driving_licence(last_name: "O'Carroll",
      #                                                 initials: "J",
      #                                                 gender: :female,
      #                                                 date_of_birth: Date.parse("1986-10-24")) #=> "OCARR815246J91HT"
      #
      # @faker.version 1.9.2
      def british_driving_licence(last_name: Faker::Name.last_name, initials: Faker::Name.initials, gender: random_gender, date_of_birth: Faker::Date.birthday(min_age: 18, max_age: 65))
        [
          gb_licence_padding(last_name, 5),
          gb_licence_year(date_of_birth, gender),
          gb_licence_padding(initials, 2),
          gb_licence_checksum
        ].join
      end

      ##
      # Produces a random Northern Irish licence number.
      #
      # @return [String]
      #
      # @example
      #   Faker::DrivingLicence.northern_irish_driving_licence #=> "70702548"
      #
      # @faker.version 1.9.2
      def northern_irish_driving_licence
        Faker::Number.number(digits: 8).to_s
      end

      ##
      # Produces a random UK driving licence number in either GB or NI format, at a rate consistent with their relative populations
      #
      # @overload uk_driving_licence(last_name, initials, gender, date_of_birth)
      #   @param last_name [String] The last name of the driving licence's owner.
      #   @param initials [String] The initials of the driving licence's owner.
      #   @param gender [String] The gender of the driving licence's owner.
      #   @param date_of_birth [String] The date of birth of the driving licence's owner.
      # @overload uk_driving_licence()
      # @return [String]
      #
      # @example
      #   Faker::DrivingLicence.uk_driving_licence             #=> "OCARR815246J91HT"
      #   Faker::DrivingLicence.uk_driving_licence             #=> "70702548"
      #
      # @faker.version 1.9.2
      def uk_driving_licence(*args)
        if Faker::Config.random.rand < NI_CHANCE
          northern_irish_driving_licence
        else
          british_driving_licence(*args)
        end
      end

      ##
      # Produces a random USA driving licence number by state code passed.
      #
      # @return [String]
      #
      # @example
      #   Faker::DrivingLicence.usa_driving_licence                 #=> "V5598249"
      #   Faker::DrivingLicence.usa_driving_licence('new mexico')   #=> "270692028"
      #   Faker::DrivingLicence.usa_driving_licence('New Mexico')   #=> "68178637"
      #
      # @faker.version 2.14.0
      def usa_driving_licence(state = 'California')
        bothify(fetch("driving_licence.usa.#{state.to_s.strip.downcase.gsub(' ', '_')}"))
      rescue I18n::MissingTranslationData => _e
        raise InvalidStatePassed, "Invalid state code passed for USA, '#{state}'"
      end

      private

      def random_gender
        %i[male female].sample(random: Faker::Config.random)
      end

      def gb_licence_padding(str, num_chars)
        prepped = str.upcase.gsub(%r{[^A-Z]}, '') + GB_PADDING
        prepped[0..(num_chars - 1)]
      end

      def gb_licence_year(dob, gender)
        decade = (dob.year / 10) % 10
        year = dob.year % 10
        month = gender == :female ? dob.month + 50 : dob.month
        # Rubocop's preferred formatting is pretty gory
        # rubocop:disable Style/FormatString
        "#{decade}#{'%02d' % month}#{'%02d' % dob.day}#{year}"
        # rubocop:enable Style/FormatString
      end

      def gb_licence_checksum
        regexify(/[0-9][A-Z][A-Z]/)
      end
    end
  end

  class InvalidStatePassed < StandardError
    def initialize(msg = 'Invalid state code passed')
      super
    end
  end
end
