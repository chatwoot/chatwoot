# frozen_string_literal: true

module Faker
  class Quotes
    class Shakespeare < Base
      class << self
        ##
        # Produces a Shakespeare quote from Hamlet.
        #
        # @return [String]
        #
        # @example
        #   Faker::Quotes::Shakespeare.hamlet_quote # => "To be, or not to be: that is the question."
        #
        # @faker.version 1.9.2
        def hamlet_quote
          sample(hamlet)
        end

        ##
        # Produces a Shakespeare quote from As You Like It.
        #
        # @return [String]
        #
        # @example
        #   Faker::Quotes::Shakespeare.as_you_like_it_quote # => "Can one desire too much of a good thing?."
        #
        # @faker.version 1.9.2
        def as_you_like_it_quote
          sample(as_you_like_it)
        end

        ##
        # Produces a Shakespeare quote from King Richard III.
        #
        # @return [String]
        #
        # @example
        #   Faker::Quotes::Shakespeare.king_richard_iii_quote # => "Now is the winter of our discontent."
        #
        # @faker.version 1.9.2
        def king_richard_iii_quote
          sample(king_richard_iii)
        end

        ##
        # Produces a Shakespeare quote from Romeo And Juliet.
        #
        # @return [String]
        #
        # @example
        #   Faker::Quotes::Shakespeare.romeo_and_juliet_quote # => "O Romeo, Romeo! wherefore art thou Romeo?."
        #
        # @faker.version 1.9.2
        def romeo_and_juliet_quote
          sample(romeo_and_juliet)
        end

        ##
        # Generates quote from Hamlet
        #
        # @return [String]
        #
        # @example
        #   Faker::Quotes::Shakespeare.hamlet   #=> "A little more than kin, and less than kind."
        #
        # @faker.version 1.9.2
        def hamlet
          fetch('shakespeare.hamlet')
        end

        ##
        # Generates quote from 'As you like it!'
        #
        # @return [String]
        #
        # @example
        #   Faker::Quotes::Shakespeare.as_you_like_it   #=> "How bitter a thing it is to look into happiness through another man's eyes!"
        #
        # @faker.version 1.9.2
        def as_you_like_it
          fetch('shakespeare.as_you_like_it')
        end

        ##
        # Returns quote from 'King Rechard III'
        #
        # @return [String]
        #
        # @example
        #   Faker::Quotes::Shakespeare  #=> "The king's name is a tower of strength."
        def king_richard_iii
          fetch('shakespeare.king_richard_iii')
        end

        ##
        # Quote from 'Romeo and Juliet'
        #
        # @return [String]
        #
        # @example
        #   Faker::Quotes::Shakespeare.romeo_and_juliet  #=> "Wisely and slow; they stumble that run fast."
        #
        # @faker.version 1.9.2
        def romeo_and_juliet
          fetch('shakespeare.romeo_and_juliet')
        end
      end
    end
  end
end
