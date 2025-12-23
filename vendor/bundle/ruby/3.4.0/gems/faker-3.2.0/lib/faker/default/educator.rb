# frozen_string_literal: true

module Faker
  class Educator < Base
    flexible :educator

    class << self
      ##
      # Produces a university name.
      #
      # @return [String]
      #
      # @example
      #   Faker::Educator.university #=> "Mallowtown Technical College"
      #
      # @faker.version 1.6.4
      def university
        parse('educator.university')
      end

      ##
      # Produces a university degree.
      #
      # @return [String]
      #
      # @example
      #   Faker::Educator.degree #=> "Associate Degree in Criminology"
      #
      # @faker.version 1.9.2
      def degree
        parse('educator.degree')
      end

      alias course degree

      ##
      # Produces a university subject.
      #
      # @return [String]
      #
      # @example
      #   Faker::Educator.subject #=> "Criminology"
      #
      # @faker.version 1.9.2
      def subject
        fetch('educator.subject')
      end

      ##
      # Produces a course name.
      #
      # @return [String]
      #
      # @example
      #   Faker::Educator.course_name #=> "Criminology 101"
      #
      # @faker.version 1.9.2
      def course_name
        numerify(parse('educator.course_name'))
      end

      ##
      # Produces a secondary school.
      #
      # @return [String]
      #
      # @example
      #   Faker::Educator.secondary_school #=> "Iceborough Secondary College"
      #
      # @faker.version 1.6.4
      def secondary_school
        parse('educator.secondary_school')
      end

      ##
      # Produces a primary school.
      #
      # @return [String]
      #
      # @example
      #   Faker::Educator.primary_school #=> "Brighthurst Elementary School"
      #
      # @faker.version next
      def primary_school
        parse('educator.primary_school')
      end

      ##
      # Produces a campus name.
      #
      # @return [String]
      #
      # @example
      #   Faker::Educator.campus #=> "Vertapple Campus"
      #
      # @faker.version 1.6.4
      def campus
        parse('educator.campus')
      end
    end
  end
end
