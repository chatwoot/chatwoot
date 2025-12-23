# frozen_string_literal: true

module Faker
  class Games
    class DnD < Base
      class << self
        ##
        # Produces the name of an alignment from Dungeons and Dragons.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::DnD.alignment #=> "Lawful Neutral"
        #
        # @faker.version 2.13.0
        def alignment
          fetch('dnd.alignments')
        end

        ##
        # Produces the name of a background from Dungeons and Dragons (PHB).
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::DnD.background #=> "Urchin"
        #
        # @faker.version 2.13.0
        def background
          fetch('dnd.backgrounds')
        end

        ##
        # Produces the name of a city from Dungeons and Dragons.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::DnD.city #=> "Earthfast"
        #
        # @faker.version 2.14.0
        def city
          fetch('dnd.cities')
        end

        ##
        # Produces the first name of a character or monster from Dungeons and Dragons.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::DnD.name #=> "Eilonwy"
        #
        # @faker.version next
        def first_name
          fetch('dnd.name.first_name')
        end

        ##
        # Produces the name of a class from Dungeons and Dragons (PHB).
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::DnD.klass #=> "Warlock"
        #
        # @faker.version 2.13.0
        def klass
          fetch('dnd.klasses')
        end

        ##
        # Produces the name of a language from Dungeons and Dragons.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::DnD.language #=> "Gnomish"
        #
        # @faker.version 2.14.0
        def language
          fetch('dnd.languages')
        end

        ##
        # Produces a last name from Dungeons and Dragons.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::DnD.last_name #=> "Leafwhisper"
        #
        # @faker.version next
        def last_name
          fetch('dnd.name.last_name')
        end

        ##
        # Produces the name of a melee weapon from Dungeons and Dragons.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::DnD.melee_weapon #=> "Handaxe"
        #
        # @faker.version 2.14.0
        def melee_weapon
          fetch('dnd.melee_weapons')
        end

        ##
        # Produces the name of a monster from Dungeons and Dragons.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::DnD.monster #=> "Manticore"
        #
        # @faker.version 2.14.0
        def monster
          fetch('dnd.monsters')
        end

        ##
        # Produces a full name from Dungeons and Dragons.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::DnD.name #=> "Drakon Blackthorn"
        #
        # @faker.version next
        def name
          "#{fetch('dnd.name.first_name')} #{fetch('dnd.name.last_name')}"
        end

        ##
        # Produces the name of a race from Dungeons and Dragons (PHB).
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::DnD.races #=> "Dwarf"
        #
        # @faker.version 2.14.0
        def race
          fetch('dnd.races')
        end

        ##
        # Produces the name of a ranged weapon from Dungeons and Dragons.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::DnD.ranged_weapon #=> "Shortbow"
        #
        # @faker.version 2.14.0
        def ranged_weapon
          fetch('dnd.ranged_weapons')
        end

        ##
        # Produces a last name from Dungeons and Dragons.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::DnD.title_name #=> "Corvus the Cunning"
        #
        # @faker.version next
        def title_name
          "#{fetch('dnd.name.first_name')} #{fetch('dnd.name.title')}"
        end
      end
    end
  end
end
