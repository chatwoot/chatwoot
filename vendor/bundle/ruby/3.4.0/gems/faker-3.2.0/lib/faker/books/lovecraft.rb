# frozen_string_literal: true

module Faker
  class Books
    class Lovecraft < Base
      class << self
        ##
        # Produces the name of a location
        #
        # @return [String]
        #
        # @example
        #   Faker::Books::Lovecraft.location #=> "Kingsport"
        #
        # @faker.version 1.9.3
        def location
          fetch('lovecraft.location')
        end

        ##
        # @param number [Integer] The number of times to repeat the chant
        # @return [String]
        #
        # @example
        #   Faker::Books::Lovecraft.fhtagn
        #     #=> "Ph'nglui mglw'nafh Cthulhu R'lyeh wgah'nagl fhtagn"
        # @example
        #   Faker::Books::Lovecraft.fhtagn(number: 3)
        #     #=> "Ph'nglui mglw'nafh Cthulhu R'lyeh wgah'nagl fht...
        #
        # @faker.version 1.9.3
        def fhtagn(number: 1)
          Array.new(number) { fetch('lovecraft.fhtagn') }.join('. ')
        end

        ##
        # Produces the name of a deity
        #
        # @return [String]
        #
        # @example
        #   Faker::Books::Lovecraft.deity #=> "Shub-Niggurath"
        #
        # @faker.version 1.9.3
        def deity
          fetch('lovecraft.deity')
        end

        ##
        # Produces the name of a tome
        #
        # @return [String]
        #
        # @example
        #   Faker::Books::Lovecraft.tome #=> "Book of Eibon"
        #
        # @faker.version 1.9.3
        def tome
          fetch('lovecraft.tome')
        end

        ##
        # Produces a random sentence
        #
        # @param word_count [Integer] The number of words to have in the sentence
        # @param random_words_to_add [Integer]
        # @param open_compounds_allowed [Boolean] If true, generated sentence can contain words having additional spaces
        #
        # @return [String]
        #
        # @example
        #   Faker::Books::Lovecraft.sentence
        #     #=> "Furtive antiquarian squamous dank cat loathsome amorphous lurk."
        # @example
        #   Faker::Books::Lovecraft.sentence(word_count: 3)
        #     #=> "Daemoniac antediluvian fainted squamous comprehension gambrel nameless singular."
        # @example
        #   Faker::Books::Lovecraft.sentence(word_count: 3, random_words_to_add: 1)
        #     #=> "Amorphous indescribable tenebrous."
        # @example
        #   Faker::Books::Lovecraft.sentence(word_count: 3, random_words_to_add: 0, open_compounds_allowed: true)
        #     #=> "Effulgence unmentionable gambrel."
        #
        # @faker.version 1.9.3
        def sentence(word_count: 4, random_words_to_add: 6, open_compounds_allowed: true)
          "#{words(number: word_count + rand(random_words_to_add.to_i).to_i, spaces_allowed: open_compounds_allowed).join(' ').capitalize}."
        end

        ##
        # Produces a random word
        #
        # @return [String]
        #
        # @example
        #   Faker::Books::Lovecraft.word #=> "furtive"
        #
        # @faker.version 1.9.3
        def word
          random_word = sample(translate('faker.lovecraft.words'))
          random_word =~ /\s/ ? word : random_word
        end

        ##
        # Produces a array of random words
        #
        # @param number [Integer] Number of words to generate
        # @param spaces_allowed [Boolean] If true, generated words can contain spaces
        #
        # @return [Array<String>]
        #
        # @example
        #   Faker::Books::Lovecraft.words
        #   #=> [
        #   #     "manuscript",
        #   #     "abnormal",
        #   #     "singular",
        #   #   ]
        # @example
        #   Faker::Books::Lovecraft.words(number: 2)
        #   #=> [
        #   #     "daemoniac",
        #   #     "cat",
        #   #   ]
        # @example
        #   Faker::Books::Lovecraft.words(number: 2, spaces_allowed: 1)
        #   #=> [
        #   #     "lurk",
        #   #     "charnel",
        #   #   ]
        #
        # @faker.version 1.9.3
        def words(number: 3, spaces_allowed: false)
          resolved_num = resolve(number)
          word_list = translate('faker.lovecraft.words')
          word_list *= ((resolved_num / word_list.length) + 1)

          return shuffle(word_list)[0, resolved_num] if spaces_allowed

          words = shuffle(word_list)[0, resolved_num]
          words.each_with_index { |w, i| words[i] = word if w =~ /\s/ }
        end

        ##
        # Produces a array of random sentences
        #
        # @param number [Integer] Number of sentences to generate
        #
        # @return [Array<String>]
        #
        # @example
        #   Faker::Books::Lovecraft.sentences
        #   #=> [
        #   #     "Nameless loathsome decadent gambrel.",
        #   #     "Ululate swarthy immemorial cat madness gibbous unmentionable unnamable.",
        #   #     "Decadent antediluvian non-euclidean tentacles amorphous tenebrous.",
        #   #   ]
        # @example
        #   Faker::Books::Lovecraft.sentences(number: 2)
        #   #=> [
        #   #     "Antediluvian amorphous unmentionable singular accursed squamous immemorial.",
        #   #     "Gambrel daemoniac gibbous stygian shunned ululate iridescence abnormal.",
        #   #   ]
        #
        # @faker.version 1.9.3
        def sentences(number: 3)
          [].tap do |sentences|
            1.upto(resolve(number)) do
              sentences << sentence(word_count: 3)
            end
          end
        end

        ##
        # Produces a random paragraph
        #
        # @param sentence_count [Integer] Number of sentences to generate
        # @param random_sentences_to_add [Integer]
        #
        # @return [String]
        #
        # @example
        #   Faker::Books::Lovecraft.paragraph
        #     #=> "Squamous nameless daemoniac fungus ululate. Cyclopean stygian decadent loathsome manuscript tenebrous. Foetid abnormal stench. Dank non-euclidean comprehension eldritch. Charnel singular shunned lurk effulgence fungus."
        # @example
        #   Faker::Books::Lovecraft.paragraph(sentence_count: 2)
        #     #=> "Decadent lurk tenebrous loathsome furtive spectral amorphous gibbous. Gambrel eldritch daemoniac cat madness comprehension stygian effulgence."
        # @example
        #   Faker::Books::Lovecraft.paragraph(sentence_count: 1, random_sentences_to_add: 1)
        #     #=> "Stench cyclopean fainted antiquarian nameless. Antiquarian ululate tenebrous non-euclidean effulgence."
        #
        # @faker.version 1.9.3
        def paragraph(sentence_count: 3, random_sentences_to_add: 3)
          sentences(number: resolve(sentence_count) + rand(random_sentences_to_add.to_i).to_i).join(' ')
        end

        ##
        # Produces a array of random paragraphs
        #
        # @param number [Integer] Number of paragraphs to generate
        #
        # @return [Array<String>]
        #
        # @example
        #   Faker::Books::Lovecraft.paragraphs
        #   #=> [
        #   #     "Noisome daemoniac gibbous abnormal antediluvian. Unutterable fung...
        #   #     "Non-euclidean immemorial indescribable accursed furtive. Dank unn...
        #   #     "Charnel antediluvian unnamable cat blasphemous comprehension tene...
        #   #   ]
        # @example
        #   Faker::Books::Lovecraft.paragraphs(number: 2)
        #   #=> [
        #   #     "Hideous amorphous manuscript antediluvian non-euclidean cat eldri...
        #   #     "Tenebrous unnamable comprehension antediluvian lurk. Lurk spectra...
        #   #   ]
        #
        # @faker.version 1.9.3
        def paragraphs(number: 3)
          [].tap do |paragraphs|
            1.upto(resolve(number)) do
              paragraphs << paragraph(sentence_count: 3)
            end
          end
        end

        ##
        # @param characters [Integer] Number of characters to generate in the paragraph
        #
        # @return [String]
        #
        # @example
        #   Faker::Books::Lovecraft.paragraph_by_chars
        #     #=> "Truffaut stumptown trust fund 8-bit messenger bag portland. Meh kombucha selvage swag biodiesel. Lomo kinfolk jean shorts asymmetrical diy. Wayfarers portland twee stumptown. Wes anderson biodiesel retro 90's pabst. Diy echo 90's mixtape semiotics. Cornho."
        # @example
        #   Faker::Books::Lovecraft.paragraph_by_chars(characters: 128)
        #     #=> "Effulgence madness noisome. Fungus stygian mortal madness amorphous dank. Decadent noisome hideous effulgence. Tentacles charne."
        #
        # @faker.version 1.9.3
        def paragraph_by_chars(characters: 256)
          paragraph = paragraph(sentence_count: 3)

          paragraph += " #{paragraph(sentence_count: 3)}" while paragraph.length < characters

          "#{paragraph[0...characters - 1]}."
        end
      end
    end
  end
end
