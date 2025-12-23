# frozen_string_literal: true

module Faker
  class ProgrammingLanguage < Base
    class << self
      ##
      # Produces the name of a programming language.
      #
      # @return [String]
      #
      # @example
      #   Faker::ProgrammingLanguage.name #=> "Ruby"
      #
      # @faker.version 1.8.5
      def name
        fetch('programming_language.name')
      end

      ##
      # Produces the name of a programming language's creator.
      #
      # @return [String]
      #
      # @example
      #   Faker::ProgrammingLanguage.creator #=> "Yukihiro Matsumoto"
      #
      # @faker.version 1.8.5
      def creator
        fetch('programming_language.creator')
      end
    end
  end
end
