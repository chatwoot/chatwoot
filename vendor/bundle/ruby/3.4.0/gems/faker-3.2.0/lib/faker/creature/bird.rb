# frozen_string_literal: true

module Faker
  class Creature
    class Bird < Base
      flexible :bird

      class << self
        ##
        # Produces a random common family name of a bird.
        #
        # @return [String]
        #
        # @example
        #   Faker::Creature::Bird.common_family_name #=> "Owls"
        #
        # @faker.version next
        def common_family_name
          fetch('creature.bird.common_family_name')
        end

        ##
        # Produces a random common taxonomic order from the class Aves
        #
        # @return [String]
        #
        # @example
        #   Faker::Creature::Bird.order #=> "Passeriformes"
        #
        # @faker.version next
        def order
          orders = I18n.translate('faker.creature.bird.order_common_map').keys
          sample(orders).to_s
        end

        ##
        # Produces a random bird anatomy word
        #
        # @return [String]
        #
        # @example
        #   Faker::Creature::Bird.anatomy #=> "rump"
        #
        # @faker.version next
        def anatomy
          fetch('creature.bird.anatomy')
        end

        ##
        # Produces a random, past tensed bird anatomy word
        #
        # @return [String]
        #
        # @example
        #   Faker::Creature::Bird.anatomy #=> "breasted"
        #
        # @faker.version next
        def anatomy_past_tense
          fetch('creature.bird.anatomy_past_tense')
        end

        ##
        # Produces a random geographical word used in describing birds
        #
        # @return [String]
        #
        # @example
        #   Faker::Creature::Bird.geo #=> "Eurasian"
        #
        # @faker.version next
        def geo
          fetch('creature.bird.geo')
        end

        ##
        # Produces a random color word used in describing birds
        #
        # @return [String]
        #
        # @example
        #   Faker::Creature::Bird.color #=> "ferruginous"
        #
        # @faker.version next
        def color
          fetch('creature.bird.colors')
        end

        ##
        # Produces a random adjective used to described birds
        #
        # @return [String]
        #
        # @example
        #   Faker::Creature::Bird.adjective #=> 'common'
        #
        # @faker.version next
        def adjective
          fetch('creature.bird.adjectives')
        end

        ##
        # Produces a random emotional adjective NOT used to described birds
        # ...but could be
        #
        # @return [String]
        #
        # @example
        #   Faker::Creature::Bird.emotional_adjective #=> 'cantankerous'
        #
        # @faker.version next
        def emotional_adjective
          fetch('creature.bird.emotional_adjectives')
        end

        ##
        # Produces a random adjective NOT used to described birds
        # ...but probably shouldn't
        #
        # @return [String]
        #
        # @example
        #   Faker::Creature::Bird.silly_adjective #=> 'drunk'
        #
        # @faker.version next
        def silly_adjective
          fetch('creature.bird.silly_adjectives')
        end

        ##
        # Produces a random common name for a bird
        #
        # @param [String | Symbol | nil] tax_order Tax
        # @return [String]
        # @raises TypeError If `tax_order` cannot be converted into a Symbol
        # @raises ArgumentError If `tax_order` is not a valid taxonomic order
        #
        # @example
        #   Faker::Creature::Bird.common_name #=> 'wren'
        #
        # @faker.version next
        def common_name(tax_order = nil)
          map = translate('faker.creature.bird.order_common_map')
          if tax_order.nil?
            sample(map.values.flatten).downcase
          else
            raise TypeError, 'tax_order parameter must be symbolizable' \
              unless tax_order.respond_to?(:to_sym)
            raise ArgumentError, "#{tax_order} is not a valid taxonomic order" \
                                 unless map.keys.include?(tax_order.to_sym)

            the_order = translate('faker.creature.bird.order_common_map')[tax_order.to_sym]
            sample(the_order).downcase
          end
        end

        ##
        # Produces a random and plausible common name for a bird
        #
        # @return [String]
        #
        # @example
        #   Faker::Creature::Bird.plausible_common_name #=> 'Hellinger's Wren'
        #
        # @faker.version next
        def plausible_common_name
          parse('creature.bird.plausible_common_names').capitalize
        end

        ##
        # Produces a random and IMplausible common name for a bird
        #
        # @return [String]
        #
        # @example
        #   Faker::Creature::Bird.implausible_common_name #=> 'Hellinger's Cantankerous Chickadee'
        #
        # @faker.version next
        def implausible_common_name
          parse('creature.bird.implausible_common_names').capitalize
        end

        ##
        # Produces a hash entry with a random order and a random common name
        # that is of that order
        #
        # @return [Hash<order,common_name>]
        #
        # @example
        #  Faker::Creature::Bird.order_with_common_name #=> {
        #    order: ''Accipitriformes',
        #    common_name: 'Osprey'
        # }
        #
        # @faker.version next
        def order_with_common_name(tax_order = nil)
          map = I18n.translate('faker.creature.bird.order_common_map')
          o = tax_order.nil? ? order : tax_order
          { order: o, common_name: sample(map[o.to_sym]) }
        end
      end
    end
  end
end
