# frozen_string_literal: true

module Faker
  # Based on Perl's Text::Lorem
  class Lorem < Base
    class << self
      ##
      # Returs the random word
      # @return [String]
      #
      # @example
      #   Faker::Lorem.word   #=> "soluto"
      #
      # @faker.version 2.1.3
      def word
        sample(translate('faker.lorem.words'))
      end

      ##
      # Generates random 3 words
      #
      # @param number [Integer] Number of words to be generated
      # @param supplemental [Boolean] Whether to attach supplemental words at the end, default is false
      #
      # @return [Array] Array for words
      #
      # @example
      #   Faker::Lorem.words                                    #=> ["hic", "quia", "nihil"]
      #   Faker::Lorem.words(number: 4)                         #=> ["est", "temporibus", "et", "quaerat"]
      #   Faker::Lorem.words(number: 4, supplemental: true)    #=> ["nisi", "sit", "allatus", "consequatur"]
      #   Faker::Lorem.words(number: 4, supplemental: true, exclude_words: 'sit') #=> ["nisi", "allatus", "consequatur", "aut"]
      #
      # @faker.version 2.1.3
      def words(number: 3, supplemental: false, exclude_words: nil)
        resolved_num = resolve(number)
        word_list = (
          translate('faker.lorem.words') +
          (supplemental ? translate('faker.lorem.supplemental') : [])
        )
        if exclude_words
          exclude_words = exclude_words.split(', ') if exclude_words.instance_of?(::String)
          word_list -= exclude_words
        end
        word_list *= ((resolved_num / word_list.length) + 1)
        shuffle(word_list)[0, resolved_num]
      end

      ##
      # Generates single character
      #
      # @return [String]
      #
      # @example
      #   Faker::Lorem.character    #=> "e"
      #
      # @faker.version 2.1.3
      def character
        sample(Types::CHARACTERS)
      end

      ##
      # Produces a random string of alphanumeric characters
      #
      # @param number [Integer] The number of characters to generate
      # @param min_alpha [Integer] The minimum number of alphabetic to add to the string
      # @param min_numeric [Integer] The minimum number of numbers to add to the string
      #
      # @return [String]
      #
      # @example
      #   Faker::Lorem.characters #=> "uw1ep04lhs0c4d931n1jmrspprf5w..."
      #   Faker::Lorem.characters(number: 10) #=> "ang9cbhoa8"
      #   Faker::Lorem.characters(number: 10, min_alpha: 4) #=> "ang9cbhoa8"
      #   Faker::Lorem.characters(number: 10, min_alpha: 4, min_numeric: 1) #=> "ang9cbhoa8"
      #
      # @faker.version 2.1.3
      def characters(number: 255, min_alpha: 0, min_numeric: 0)
        Alphanumeric.alphanumeric(number: number, min_alpha: min_alpha, min_numeric: min_numeric)
      end

      ##
      # Generates the emoji
      #
      # @return [String]
      #
      # @example
      #   Faker::Lorem.multibyte  #=> "😀"
      #   Faker::Lorem.multibyte  #=> "❤"
      #
      # @faker.version 2.1.3
      def multibyte
        sample(translate('faker.lorem.multibyte')).pack('C*').force_encoding('utf-8')
      end

      ##
      # Generates sentence
      #
      # @param word_count [Integer] How many words should be there in a sentence, default to 4
      # @param supplemental [Boolean] Add supplemental words, default to false
      # @param random_words_to_add [Integer] Add any random words, default to 0
      #
      # @return [String]
      #
      # @example
      #   Faker::Lorem.sentence                                                             #=> "Magnam qui aut quidem."
      #   Faker::Lorem.sentence(word_count: 5)                                              #=> "Voluptas rerum aut aliquam velit."
      #   Faker::Lorem.sentence(word_count: 5, supplemental: true)                          #=> "Aut viscus curtus votum iusto."
      #   Faker::Lorem.sentence(word_count: 5, supplemental: true, random_words_to_add:2)   #=> "Crinis quo cruentus velit animi vomer."
      #
      # @faker.version 2.1.3
      def sentence(word_count: 4, supplemental: false, random_words_to_add: 0, exclude_words: nil)
        words(number: word_count + rand(random_words_to_add.to_i), supplemental: supplemental, exclude_words: exclude_words).join(locale_space).capitalize + locale_period
      end

      ##
      # Generates three sentences
      #
      # @param number [Integer] How many sentences to be generated, default to 3
      # @param supplemental [Boolean] Should add supplemental words, defaults to false
      #
      # @return [Array] Returns array for sentences.
      #
      # @example
      #   Faker::Lorem.sentences                                  #=> ["Possimus non tenetur.", "Nulla non excepturi.", "Quisquam rerum facilis."]
      #   Faker::Lorem.sentences(number: 2)                       #=> ["Nulla est natus.", "Perferendis autem cum."]
      #   Faker::Lorem.sentences(number: 2, supplemental: true)   #=> ["Cito cena ad.", "Solvo animus allatus."]
      #
      # @faker.version 2.1.3
      def sentences(number: 3, supplemental: false, exclude_words: nil)
        1.upto(resolve(number)).collect { sentence(word_count: 3, supplemental: supplemental, exclude_words: exclude_words) }
      end

      ##
      # Generates three sentence paragraph
      #
      # @param sentence_count [Integer] Number of sentences in the paragraph
      # @param supplemental [Boolean]
      # @param random_sentences_to_add [Integer]
      #
      # @return [String]
      #
      # @example
      #   Faker::Lorem.paragraph
      #     #=> "Impedit et est. Aliquid deleniti necessitatibus. Et aspernatur minima."
      #   Faker::Lorem.paragraph(sentence_count: 2)
      #     #=> "Rerum fugit vitae. Et atque autem."
      #   Faker::Lorem.paragraph(sentence_count: 2, supplemental: true)
      #     #=> "Terreo coerceo utor. Vester sunt cogito."
      #   Faker::Lorem.paragraph(sentence_count: 2, supplemental: true, random_sentences_to_add: 2)
      #     #=> "Texo tantillus tamisium. Tribuo amissio tamisium. Facere aut canis."
      #
      # @faker.version 2.1.3
      def paragraph(sentence_count: 3, supplemental: false, random_sentences_to_add: 0, exclude_words: nil)
        sentences(number: resolve(sentence_count) + rand(random_sentences_to_add.to_i), supplemental: supplemental, exclude_words: exclude_words).join(locale_space)
      end

      ##
      # Generates three paragraphs
      #
      # @param number [Integer]
      # @param supplemental [Boolean]
      #
      # @return [Array]
      #
      # @example
      #   Faker::Lorem.paragraphs
      #   Faker::Lorem.paragraphs(number:2)
      #   Faker::Lorem.paragraphs(number:2, supplemental: true)
      #
      # @faker.version 2.1.3
      def paragraphs(number: 3, supplemental: false, exclude_words: nil)
        1.upto(resolve(number)).collect { paragraph(sentence_count: 3, supplemental: supplemental, exclude_words: exclude_words) }
      end

      ##
      # Generates paragraph with 256 characters
      #
      # @param number [Integer]
      # @param supplemental [Boolean]
      #
      # @return [String]
      #
      # @example
      #   Faker::Lorem.paragraph_by_chars
      #   Faker::Lorem.paragraph_by_chars(number: 20)                       #=> "Sit modi alias. Imp."
      #   Faker::Lorem.paragraph_by_chars(number: 20, supplemental: true)   #=> "Certus aveho admove."
      #
      # @faker.version 2.1.3
      def paragraph_by_chars(number: 256, supplemental: false)
        paragraph = paragraph(sentence_count: 3, supplemental: supplemental)

        paragraph += " #{paragraph(sentence_count: 3, supplemental: supplemental)}" while paragraph.length < number

        "#{paragraph[0...number - 1]}."
      end

      ##
      # Returns the question with 4 words
      #
      # @param word_count [Integer]
      # @param supplemental [Boolean]
      # @param random_words_to_add [Integer]
      #
      # @return [String]
      #
      # @example
      #   Faker::Lorem.question                                                               #=> "Natus deleniti sequi laudantium?"
      #   Faker::Lorem.question(word_count: 2)                                                #=> "Quo ut?"
      #   Faker::Lorem.question(word_count: 2, supplemental: true)                            #=> "Terga consequatur?"
      #   Faker::Lorem.question(word_count: 2, supplemental: true, random_words_to_add: 2)    #=> "Depulso uter ut?"
      #
      # @faker.version 2.1.3
      def question(word_count: 4, supplemental: false, random_words_to_add: 0, exclude_words: nil)
        words(number: word_count + rand(random_words_to_add), supplemental: supplemental, exclude_words: exclude_words).join(' ').capitalize + locale_question_mark
      end

      ##
      # Generates array of three questions
      #
      # @param number [Integer]
      # @param supplemental [Boolean]
      #
      # @return [Array]
      #
      # @example
      #   Faker::Lorem.questions                                  #=> ["Amet culpa enim?", "Voluptatem deleniti numquam?", "Veniam non cum?"]
      #   Faker::Lorem.questions(number: 2)                       #=> ["Minus occaecati nobis?", "Veniam et alias?"]
      #   Faker::Lorem.questions(number: 2, supplemental: true)   #=> ["Acceptus subito cetera?", "Aro sulum cubicularis?"]
      #
      # @faker.version 2.1.3
      def questions(number: 3, supplemental: false, exclude_words: nil)
        1.upto(resolve(number)).collect { question(word_count: 3, supplemental: supplemental, exclude_words: exclude_words) }
      end

      private

      def locale_period
        translate('faker.lorem.punctuation.period') || '.'
      end

      def locale_space
        translate('faker.lorem.punctuation.space') || ' '
      end

      def locale_question_mark
        translate('faker.lorem.punctuation.question_mark') || '?'
      end
    end
  end
end
