# frozen_string_literal: true

module Faker
  class Quotes
    class Chiquito < Base
      class << self
        ##
        # Produces an Expression from Chiquito
        #
        # @return [String]
        #
        # @example
        #   Faker::Quotes::Chiquito.expression # => "Ereh un torpedo!"
        #
        # @faker.version 2.11.0
        def expression
          sample(expressions)
        end

        ##
        # Produces a concept from Chiquito
        #
        # @return [String]
        #
        # @example
        #   Faker::Quotes::Chiquito.term # => "Fistro"
        #
        # @faker.version 2.11.0
        def term
          sample(terms)
        end

        ##
        # Produces a joke from Chiquito
        #
        # @return [String]
        #
        # @example
        #   Faker::Quotes::Chiquito.joke # => "- Papar papar llevame al circo!
        #                                      - Noorl! El que quiera verte que venga a la casa"
        #
        # @faker.version 2.11.0
        def joke
          sample(jokes)
        end

        ##
        # Produces a sentence from Chiquito
        #
        # @return [String]
        #
        # @example
        #   Faker::Quotes::Chiquito.sentence # => "Te llamo trigo por no llamarte Rodrigo"
        #
        # @faker.version 2.11.0
        def sentence
          sample(sentences)
        end

        private

        def expressions
          fetch('chiquito.expressions')
        end

        def terms
          fetch('chiquito.terms')
        end

        def jokes
          fetch('chiquito.jokes')
        end

        def sentences
          fetch('chiquito.sentences')
        end
      end
    end
  end
end
