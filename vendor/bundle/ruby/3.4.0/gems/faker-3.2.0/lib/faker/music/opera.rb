# frozen_string_literal: true

module Faker
  # A generator of titles of operas by various composers
  class Music
    class Opera < Base
      class << self
        ##
        # Produces the title of an opera by Giuseppe Verdi.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Opera.verdi #=> "Il Trovatore"
        #
        # @faker.version 1.9.4
        def verdi
          fetch('opera.italian.by_giuseppe_verdi')
        end

        ##
        # Produces the title of an opera by Gioacchino Rossini.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Opera.rossini #=> "Il Barbiere di Siviglia"
        #
        # @faker.version 1.9.4
        def rossini
          fetch('opera.italian.by_gioacchino_rossini')
        end

        ##
        # Produces the title of an opera by Gaetano Donizetti.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Opera.donizetti #=> "Lucia di Lammermoor"
        #
        # @faker.version 1.9.4
        def donizetti
          fetch('opera.italian.by_gaetano_donizetti')
        end

        ##
        # Produces the title of an opera by Vincenzo Bellini.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Opera.bellini #=> "Norma"
        #
        # @faker.version 1.9.4
        def bellini
          fetch('opera.italian.by_vincenzo_bellini')
        end

        ##
        # Produces the title of an opera by Wolfgang Amadeus Mozart.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Opera.mozart #=> "Die Zauberfloete"
        #
        # @faker.version next
        def mozart
          fetch('opera.italian.by_wolfgang_amadeus_mozart') +
            fetch('opera.german.by_wolfgang_amadeus_mozart')
        end

        ##
        # Produces the title of an Italian opera by Wolfgang Amadeus Mozart.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Opera.mozart_it #=> "Cosi fan tutte"
        #
        # @faker.version next
        def mozart_italian
          fetch('opera.italian.by_wolfgang_amadeus_mozart')
        end

        ##
        # Produces the title of a German opera by Wolfgang Amadeus Mozart.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Opera.mozart_ger #=> "Die Zauberfloete"
        #
        # @faker.version next
        def mozart_german
          fetch('opera.german.by_wolfgang_amadeus_mozart')
        end

        ##
        # Produces the title of an opera by Christoph Willibald Gluck.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Opera.gluck #=> "Orfeo ed Euridice"
        #
        # @faker.version next
        def gluck
          fetch('opera.italian.by_christoph_willibald_gluck') +
            fetch('opera.french.by_christoph_willibald_gluck')
        end

        ##
        # Produces the title of an Italian opera by Christoph Willibald Gluck.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Opera.gluck_it #=> "Orfeo ed Euridice"
        #
        # @faker.version next
        def gluck_italian
          fetch('opera.italian.by_christoph_willibald_gluck')
        end

        ##
        # Produces the title of a French opera by Christoph Willibald Gluck.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Opera.gluck_fr #=> "Orphee et Euridice"
        #
        # @faker.version next
        def gluck_french
          fetch('opera.french.by_christoph_willibald_gluck')
        end

        ##
        # Produces the title of an opera by Ludwig van Beethoven.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Opera.beethoven #=> "Fidelio"
        #
        # @faker.version next
        def beethoven
          fetch('opera.german.by_ludwig_van_beethoven')
        end

        ##
        # Produces the title of an opera by Carl Maria von Weber.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Opera.weber #=> "Der Freischuetz"
        #
        # @faker.version next
        def weber
          fetch('opera.german.by_carl_maria_von_weber')
        end

        ##
        # Produces the title of an opera by Richard Strauss.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Opera.strauss #=> "Elektra"
        #
        # @faker.version next
        def strauss
          fetch('opera.german.by_richard_strauss')
        end

        ##
        # Produces the title of an opera by Richard Wagner.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Opera.wagner #=> "Tristan und Isolde"
        #
        # @faker.version next
        def wagner
          fetch('opera.german.by_richard_wagner')
        end

        ##
        # Produces the title of an opera by Robert Schumann.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Opera.schumann #=> "Genoveva"
        #
        # @faker.version next
        def schumann
          fetch('opera.german.by_robert_schumann')
        end

        ##
        # Produces the title of an opera by Franz Schubert.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Opera.schubert #=> "Alfonso und Estrella"
        #
        # @faker.version next
        def schubert
          fetch('opera.german.by_franz_schubert')
        end

        ##
        # Produces the title of an opera by Alban Berg.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Opera.berg #=> "Wozzeck"
        #
        # @faker.version next
        def berg
          fetch('opera.german.by_alban_berg')
        end

        ##
        # Produces the title of an opera by Maurice Ravel.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Opera.ravel #=> "L'enfant et les sortileges"
        #
        # @faker.version next
        def ravel
          fetch('opera.french.by_maurice_ravel')
        end

        ##
        # Produces the title of an opera by Hector Berlioz.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Opera.berlioz #=> "Les Troyens"
        #
        # @faker.version next
        def berlioz
          fetch('opera.french.by_hector_berlioz')
        end

        ##
        # Produces the title of an opera by Georges Bizet.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Opera.bizet #=> "Carmen"
        #
        # @faker.version next
        def bizet
          fetch('opera.french.by_georges_bizet')
        end

        ##
        # Produces the title of an opera by Charles Gounod.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Opera.gounod #=> "Faust"
        #
        # @faker.version next
        def gounod
          fetch('opera.french.by_charles_gounod')
        end

        ##
        # Produces the title of an opera by Camille Saint-Saens.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Opera.saint_saens #=> "Samson and Delilah"
        #
        # @faker.version next
        def saint_saens
          fetch('opera.french.by_camille_saint_saens')
        end
      end
    end
  end
end
