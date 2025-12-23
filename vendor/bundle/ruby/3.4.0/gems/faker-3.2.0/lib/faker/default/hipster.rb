# frozen_string_literal: true

module Faker
  class Hipster < Base
    class << self
      ##
      # Produces a random hipster word.
      #
      # @return [String]
      #
      # @example
      #   Faker::Hipster.word #=> "irony"
      #
      # @faker.version 1.6.0
      def word
        random_word = sample(translate('faker.hipster.words'))
        random_word =~ /\s/ ? word : random_word
      end

      ##
      # Produces a random hipster word.
      #
      # @param number [Integer] Specifies the number of words returned
      # @param supplemental [Boolean] Specifies if the words are supplemental
      # @param spaces_allowed [Boolean] Specifies if the words may contain spaces
      # @return [Array<String>]
      #
      # @example
      #   Faker::Hipster.words #=> ["pug", "pitchfork", "chia"]
      #   Faker::Hipster.words(number: 4) #=> ["ugh", "cardigan", "poutine", "stumptown"]
      #   Faker::Hipster.words(number: 4, supplemental: true) #=> ["iste", "seitan", "normcore", "provident"]
      #   Faker::Hipster.words(number: 4, supplemental: true, spaces_allowed: true) #=> ["qui", "magni", "craft beer", "est"]
      #
      # @faker.version 1.6.0
      def words(number: 3, supplemental: false, spaces_allowed: false)
        resolved_num = resolve(number)
        word_list = (
          translate('faker.hipster.words') +
          (supplemental ? translate('faker.lorem.words') : [])
        )
        word_list *= ((resolved_num / word_list.length) + 1)

        return shuffle(word_list)[0, resolved_num] if spaces_allowed

        words = shuffle(word_list)[0, resolved_num]
        words.each_with_index { |w, i| words[i] = word if w =~ /\s/ }
      end

      ##
      # Produces a random hipster sentence.
      #
      # @param word_count [Integer] Specifies the number of words in the sentence
      # @param supplemental [Boolean] Specifies if the words are supplemental
      # @param random_words_to_add [Integer] Specifies the number of random words to add
      # @param open_compounds_allowed [Boolean] Specifies if the generated sentence can contain words having additional spaces
      # @return [String]
      #
      # @example
      #   Faker::Hipster.sentence #=> "Park iphone leggings put a bird on it."
      #   Faker::Hipster.sentence(word_count: 3) #=> "Pour-over swag godard."
      #   Faker::Hipster.sentence(word_count: 3, supplemental: true) #=> "Beard laboriosam sequi celiac."
      #   Faker::Hipster.sentence(word_count: 3, supplemental: false, random_words_to_add: 4) #=> "Bitters retro mustache aesthetic biodiesel 8-bit."
      #   Faker::Hipster.sentence(word_count: 3, supplemental: true, random_words_to_add: 4) #=> "Occaecati deleniti messenger bag meh crucifix autem."
      #   Faker::Hipster.sentence(word_count: 3, supplemental: true, random_words_to_add: 0, open_compounds_allowed: true) #=> "Kale chips nihil eos."
      #   Faker::Hipster.sentence(word_count: 3, supplemental: true, random_words_to_add: 0, open_compounds_allowed: false) #=> "Dreamcatcher umami fixie."
      #
      # @faker.version 1.6.0
      def sentence(word_count: 4, supplemental: false, random_words_to_add: 6, open_compounds_allowed: true)
        "#{words(number: word_count + rand(random_words_to_add.to_i).to_i, supplemental: supplemental, spaces_allowed: open_compounds_allowed).join(' ').capitalize}."
      end

      ##
      # Produces random hipster sentences.
      #
      # @param number [Integer] Specifies the number of sentences returned
      # @param supplemental [Boolean] Specifies if the words are supplemental
      # @return [Array<String>]
      #
      # @example
      #   Faker::Hipster.sentences #=> ["Godard pitchfork vinegar chillwave everyday 90's whatever.", "Pour-over artisan distillery street waistcoat.", "Salvia yr leggings franzen blue bottle."]
      #   Faker::Hipster.sentences(number: 1) #=> ["Before they sold out pinterest venmo umami try-hard ugh hoodie artisan."]
      #   Faker::Hipster.sentences(number: 1, supplemental: true) #=> ["Et sustainable optio aesthetic et."]
      #
      # @faker.version 1.6.0
      def sentences(number: 3, supplemental: false)
        [].tap do |sentences|
          1.upto(resolve(number)) do
            sentences << sentence(word_count: 3, supplemental: supplemental)
          end
        end
      end

      ##
      # Produces a random hipster paragraph.
      #
      # @param sentence_count [Integer] Specifies the number of sentences in the paragraph
      # @param supplemental [Boolean] Specifies if the words are supplemental
      # @param random_sentences_to_add [Boolean] Specifies the number of random sentences to add
      # @return [String]
      #
      # @example
      #   Faker::Hipster.paragraph #=> "Migas fingerstache pbr&b tofu. Polaroid distillery typewriter echo tofu actually. Slow-carb fanny pack pickled direct trade scenester mlkshk plaid. Banjo venmo chambray cold-pressed typewriter. Fap skateboard intelligentsia."
      #   Faker::Hipster.paragraph(sentence_count: 2) #=> "Yolo tilde farm-to-table hashtag. Lomo kitsch disrupt forage +1."
      #   Faker::Hipster.paragraph(sentence_count: 2, supplemental: true) #=> "Typewriter iste ut viral kombucha voluptatem. Sint voluptates saepe. Direct trade irony chia excepturi yuccie. Biodiesel esse listicle et quam suscipit."
      #   Faker::Hipster.paragraph(sentence_count: 2, supplemental: false, random_sentences_to_add: 4) #=> "Selvage vhs chartreuse narwhal vinegar. Authentic vinyl truffaut carry vhs pop-up. Hammock everyday iphone locavore thundercats bitters vegan goth. Fashion axe banh mi shoreditch whatever artisan."
      #   Faker::Hipster.paragraph(sentence_count: 2, supplemental: true, random_sentences_to_add: 4) #=> "Deep v gluten-free unde waistcoat aperiam migas voluptas dolorum. Aut drinking illo sustainable sapiente. Direct trade fanny pack kale chips ennui semiotics."
      #
      # @faker.version 1.6.0
      def paragraph(sentence_count: 3, supplemental: false, random_sentences_to_add: 3)
        sentences(number: resolve(sentence_count) + rand(random_sentences_to_add.to_i).to_i, supplemental: supplemental).join(' ')
      end

      ##
      # Produces random hipster paragraphs.
      #
      # @param number [Integer] Specifies the number of paragraphs
      # @param supplemental [Boolean] Specifies if the words are supplemental
      # @return [Array<String>]
      #
      # @example
      #   Faker::Hipster.paragraphs #=> ["Tilde microdosing blog cliche meggings. Intelligentsia five dollar toast forage yuccie. Master kitsch knausgaard. Try-hard everyday trust fund mumblecore.", "Normcore viral pickled. Listicle humblebrag swag tote bag. Taxidermy street hammock neutra butcher cred kale chips. Blog portland humblebrag trust fund irony.", "Single-origin coffee fixie cleanse tofu xoxo. Post-ironic tote bag ramps gluten-free locavore mumblecore hammock. Umami loko twee. Ugh kitsch before they sold out."]
      #   Faker::Hipster.paragraphs(number: 1) #=> ["Skateboard cronut synth +1 fashion axe. Pop-up polaroid skateboard asymmetrical. Ennui fingerstache shoreditch before they sold out. Tattooed pitchfork ramps. Photo booth yr messenger bag raw denim bespoke locavore lomo synth."]
      #   Faker::Hipster.paragraphs(number: 1, supplemental: true) #=> ["Quae direct trade pbr&b quo taxidermy autem loko. Umami quas ratione migas cardigan sriracha minima. Tenetur perspiciatis pickled sed eum doloribus truffaut. Excepturi dreamcatcher meditation."]
      #
      # @faker.version 1.6.0
      def paragraphs(number: 3, supplemental: false)
        [].tap do |paragraphs|
          1.upto(resolve(number)) do
            paragraphs << paragraph(sentence_count: 3, supplemental: supplemental)
          end
        end
      end

      ##
      # Produces a random hipster paragraph by characters.
      #
      # @param characters [Integer] Specifies the number of characters in the paragraph
      # @param supplemental [Boolean] Specifies if the words are supplemental
      # @return [String]
      #
      # @example
      #   Faker::Hipster.paragraph_by_chars #=> "Truffaut stumptown trust fund 8-bit messenger bag portland. Meh kombucha selvage swag biodiesel. Lomo kinfolk jean shorts asymmetrical diy. Wayfarers portland twee stumptown. Wes anderson biodiesel retro 90's pabst. Diy echo 90's mixtape semiotics. Cornho."
      #   Faker::Hipster.paragraph_by_chars(characters: 256, supplemental: false) #=> "Hella kogi blog narwhal sartorial selfies mustache schlitz. Bespoke normcore kitsch cred hella fixie. Park aesthetic fixie migas twee. Cliche mustache brunch tumblr fixie godard. Drinking pop-up synth hoodie dreamcatcher typewriter. Kitsch biodiesel green."
      #
      # @faker.version 1.6.0
      def paragraph_by_chars(characters: 256, supplemental: false)
        paragraph = paragraph(sentence_count: 3, supplemental: supplemental)

        paragraph += " #{paragraph(sentence_count: 3, supplemental: supplemental)}" while paragraph.length < characters

        "#{paragraph[0...characters - 1]}."
      end
    end
  end
end
